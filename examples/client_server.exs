# Run with: mix run examples/client_server.exs
#
# Demonstrates the full A2A client/server architecture over HTTP:
#   - Bandit serves agents via A2A.Plug
#   - A2A.Client discovers and communicates with them remotely

# ─── Agent Definitions ──────────────────────────────────────────────

defmodule Example.EchoAgent do
  use A2A.Agent,
    name: "echo",
    description: "Echoes messages back",
    skills: [
      %{id: "echo", name: "Echo", description: "Repeats your input", tags: ["demo"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""
    {:reply, [A2A.Part.Text.new("You said: #{text}")]}
  end
end

defmodule Example.OrderAgent do
  use A2A.Agent,
    name: "order-bot",
    description: "Takes orders via multi-turn conversation",
    skills: [
      %{id: "order", name: "Order", description: "Place an order", tags: ["demo"]}
    ]

  @impl A2A.Agent
  def handle_message(message, context) do
    text = A2A.Message.text(message) || ""

    cond do
      length(context.history) == 1 ->
        {:input_required, [A2A.Part.Text.new("What size? (small/medium/large)")]}

      length(context.history) == 3 ->
        {:input_required, [A2A.Part.Text.new("Any extras? (e.g., gift wrap)")]}

      true ->
        item = A2A.Message.text(Enum.at(context.history, 0))
        size = A2A.Message.text(Enum.at(context.history, 2))

        {:reply,
         [A2A.Part.Text.new("Order confirmed: #{size} #{item}, extras: #{text}")]}
    end
  end
end

defmodule Example.CountdownAgent do
  use A2A.Agent,
    name: "countdown",
    description: "Streams a countdown",
    skills: [
      %{id: "count", name: "Countdown", description: "Counts down from N", tags: ["demo"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    n =
      case Integer.parse(A2A.Message.text(message) || "5") do
        {num, _} -> num
        :error -> 5
      end

    stream =
      Stream.map(n..1//-1, fn i ->
        A2A.Part.Text.new("#{i}...")
      end)

    {:stream, stream}
  end
end

# ─── Start Servers ──────────────────────────────────────────────────

IO.puts("=== A2A Client/Server Demo ===\n")

agents = [
  {Example.EchoAgent, 4001},
  {Example.OrderAgent, 4002},
  {Example.CountdownAgent, 4003}
]

# Start agent GenServers
for {mod, _port} <- agents do
  {:ok, _} = mod.start_link()
end

# Start a Bandit HTTP server for each agent
servers =
  for {mod, port} <- agents do
    {:ok, pid} =
      Bandit.start_link(
        plug: {A2A.Plug, agent: mod, base_url: "http://localhost:#{port}"},
        port: port,
        startup_log: false
      )

    {mod, port, pid}
  end

# Brief pause for servers to bind
Process.sleep(100)

IO.puts("Servers running:")

for {mod, port, _pid} <- servers do
  IO.puts("  #{inspect(mod)} on port #{port}")
end

IO.puts("")

# ─── 1. Discovery ───────────────────────────────────────────────────

IO.puts("--- 1. Discovery ---")

for {_mod, port, _pid} <- servers do
  {:ok, card} = A2A.Client.discover("http://localhost:#{port}")
  skills = Enum.map(card.skills, & &1.name) |> Enum.join(", ")
  IO.puts("  #{card.name} — #{card.description} [#{skills}]")
  IO.puts("    url: #{card.url}")
end

IO.puts("")

# ─── 2. Simple Message (Echo) ──────────────────────────────────────

IO.puts("--- 2. Simple Message (Echo) ---")

client = A2A.Client.new("http://localhost:4001")
{:ok, task} = A2A.Client.send_message(client, "Hello over HTTP!")

IO.puts("  Task ID: #{task.id}")
IO.puts("  Status:  #{task.status.state}")

reply_text =
  task.history
  |> Enum.filter(&(&1.role == :agent))
  |> List.last()
  |> A2A.Message.text()

IO.puts("  Reply:   #{reply_text}")
IO.puts("")

# ─── 3. Multi-Turn (Order) ─────────────────────────────────────────

IO.puts("--- 3. Multi-Turn (Order) ---")

client = A2A.Client.new("http://localhost:4002")

{:ok, task} = A2A.Client.send_message(client, "Widget")
IO.puts("  [1] Status: #{task.status.state}")
IO.puts("      Agent:  #{A2A.Message.text(task.status.message)}")

{:ok, task} = A2A.Client.send_message(client, "large", task_id: task.id)
IO.puts("  [2] Status: #{task.status.state}")
IO.puts("      Agent:  #{A2A.Message.text(task.status.message)}")

{:ok, task} = A2A.Client.send_message(client, "gift wrap", task_id: task.id)
IO.puts("  [3] Status: #{task.status.state}")

reply_text =
  task.history
  |> Enum.filter(&(&1.role == :agent))
  |> List.last()
  |> A2A.Message.text()

IO.puts("      Reply:  #{reply_text}")
IO.puts("      History: #{length(task.history)} messages")
IO.puts("")

# ─── 4. Streaming (Countdown) ──────────────────────────────────────

IO.puts("--- 4. Streaming (Countdown) ---")

client = A2A.Client.new("http://localhost:4003")
{:ok, stream} = A2A.Client.stream_message(client, "5")

IO.write("  Stream: ")

Enum.each(stream, fn
  %A2A.Task{} = task ->
    IO.write("[task:#{task.status.state}] ")

  %A2A.Event.ArtifactUpdate{artifact: artifact} ->
    text = Enum.map(artifact.parts, &A2A.Message.text(%A2A.Message{role: :agent, parts: [&1]}))
    IO.write(Enum.join(text))

  %A2A.Event.StatusUpdate{status: status, final: final} ->
    label = if final, do: "[final:#{status.state}]", else: "[status:#{status.state}]"
    IO.write(label)

  other ->
    IO.write("[#{inspect(other)}]")
end)

IO.puts("")
IO.puts("")

# ─── 5. Task Management ────────────────────────────────────────────

IO.puts("--- 5. Task Management ---")

# Re-fetch a completed task from the echo agent
client = A2A.Client.new("http://localhost:4001")
{:ok, task} = A2A.Client.send_message(client, "fetch me later")
IO.puts("  Created task: #{task.id} (#{task.status.state})")

{:ok, fetched} = A2A.Client.get_task(client, task.id)
IO.puts("  Fetched task: #{fetched.id} (#{fetched.status.state})")

# Cancel a task (send to order agent, then cancel before completing)
client = A2A.Client.new("http://localhost:4002")
{:ok, task} = A2A.Client.send_message(client, "Cancel me")
IO.puts("  Created task: #{task.id} (#{task.status.state})")

{:ok, canceled} = A2A.Client.cancel_task(client, task.id)
IO.puts("  Canceled task: #{canceled.id} (#{canceled.status.state})")

IO.puts("")

# ─── Cleanup ────────────────────────────────────────────────────────

for {_mod, _port, pid} <- servers do
  Supervisor.stop(pid)
end

IO.puts("Done!")
