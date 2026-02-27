# Run with: mix run examples/demo.exs

# ─── 1. Define Agents ────────────────────────────────────────────────

defmodule Demo.EchoAgent do
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

defmodule Demo.PizzaAgent do
  use A2A.Agent,
    name: "pizza-bot",
    description: "Takes pizza orders (multi-turn)",
    skills: [
      %{id: "order", name: "Order Pizza", description: "Place a pizza order", tags: ["food"]}
    ]

  @impl A2A.Agent
  def handle_message(message, context) do
    text = A2A.Message.text(message) || ""

    cond do
      # First message — ask for size
      length(context.history) == 1 ->
        {:input_required, [A2A.Part.Text.new("What size? (small/medium/large)")]}

      # Second message — ask for toppings
      length(context.history) == 3 ->
        {:input_required, [A2A.Part.Text.new("What toppings? (e.g., pepperoni, mushroom)")]}

      # Third message — confirm order
      true ->
        first_msg = A2A.Message.text(Enum.at(context.history, 0))
        size = A2A.Message.text(Enum.at(context.history, 2))
        toppings = text

        {:reply,
         [
           A2A.Part.Text.new("Order confirmed!"),
           A2A.Part.Data.new(%{
             pizza: first_msg,
             size: size,
             toppings: toppings,
             status: "preparing"
           })
         ]}
    end
  end
end

defmodule Demo.CountdownAgent do
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

# ─── 2. Start Agents ─────────────────────────────────────────────────

IO.puts("=== A2A Agent Demo ===\n")

{:ok, _} = Demo.EchoAgent.start_link()
{:ok, _} = Demo.PizzaAgent.start_link()
{:ok, _} = Demo.CountdownAgent.start_link()

# ─── 3. Simple Call ───────────────────────────────────────────────────

IO.puts("--- Echo Agent ---")
{:ok, task} = A2A.call(Demo.EchoAgent, "Hello, agent!")
IO.puts("Status: #{task.status.state}")
IO.puts("Reply:  #{A2A.Message.text(List.last(task.history))}")
IO.puts("")

# ─── 4. Multi-Turn Conversation ──────────────────────────────────────

IO.puts("--- Pizza Agent (multi-turn) ---")

{:ok, task} = A2A.call(Demo.PizzaAgent, "Margherita please")
IO.puts("[1] Status: #{task.status.state}")
IO.puts("    Agent:  #{A2A.Message.text(task.status.message)}")

{:ok, task} = A2A.call(Demo.PizzaAgent, "large", task_id: task.id)
IO.puts("[2] Status: #{task.status.state}")
IO.puts("    Agent:  #{A2A.Message.text(task.status.message)}")

{:ok, task} = A2A.call(Demo.PizzaAgent, "pepperoni, olives", task_id: task.id)
IO.puts("[3] Status: #{task.status.state}")

# Show the final artifact
[artifact | _] = task.artifacts
IO.puts("    Reply:  #{inspect(Enum.map(artifact.parts, fn
  %A2A.Part.Text{text: t} -> t
  %A2A.Part.Data{data: d} -> d
end))}")

IO.puts("    History: #{length(task.history)} messages")
IO.puts("")

# ─── 5. Streaming ────────────────────────────────────────────────────

IO.puts("--- Countdown Agent (streaming) ---")

{:ok, task, stream} = A2A.stream(Demo.CountdownAgent, "5")
IO.puts("Status before consuming: #{task.status.state}")

IO.write("Stream: ")

stream
|> Stream.each(fn %A2A.Part.Text{text: text} -> IO.write(text <> " ") end)
|> Stream.run()

IO.puts("🎉")

# Give the cast a moment to process
Process.sleep(10)
{:ok, completed} = Demo.CountdownAgent.get_task(task.id)
IO.puts("Status after consuming:  #{completed.status.state}")
IO.puts("Artifacts: #{length(completed.artifacts)}")
IO.puts("")

# ─── 6. Agent Card ───────────────────────────────────────────────────

IO.puts("--- Agent Cards ---")

for mod <- [Demo.EchoAgent, Demo.PizzaAgent, Demo.CountdownAgent] do
  card = mod.agent_card()
  skills = Enum.map(card.skills, & &1.name) |> Enum.join(", ")
  IO.puts("  #{card.name} v#{card.version} — #{card.description} [#{skills}]")
end

IO.puts("\nDone!")
