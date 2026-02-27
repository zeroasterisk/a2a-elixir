# Run with: mix run examples/supervisor_demo.exs
#
# Demonstrates A2A.AgentSupervisor and A2A.Registry:
#   - One supervisor starts a registry + multiple agents
#   - Registry enables skill-based agent discovery
#   - Agents are callable by module name as usual

# ─── 1. Define Agents ────────────────────────────────────────────────

defmodule Fleet.PricingAgent do
  use A2A.Agent,
    name: "pricing",
    description: "Calculates product pricing",
    skills: [
      %{id: "quote", name: "Quote", description: "Get a price quote", tags: ["finance", "pricing"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""
    # Fake pricing logic
    hash = :erlang.phash2(text, 1000)
    price = 10.0 + hash / 10.0
    {:reply, [A2A.Part.Data.new(%{item: text, price: price, currency: "USD"})]}
  end
end

defmodule Fleet.RiskAgent do
  use A2A.Agent,
    name: "risk-assessor",
    description: "Evaluates transaction risk",
    skills: [
      %{id: "assess", name: "Risk Assessment", description: "Score transaction risk",
        tags: ["finance", "risk"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""
    score = rem(:erlang.phash2(text), 100)

    level =
      cond do
        score < 30 -> "low"
        score < 70 -> "medium"
        true -> "high"
      end

    {:reply, [A2A.Part.Data.new(%{score: score, level: level})]}
  end
end

defmodule Fleet.SummaryAgent do
  use A2A.Agent,
    name: "summarizer",
    description: "Summarizes text input",
    skills: [
      %{id: "summarize", name: "Summarize", description: "Produce a brief summary",
        tags: ["text", "nlp"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""
    words = String.split(text)
    summary = words |> Enum.take(5) |> Enum.join(" ")
    {:reply, [A2A.Part.Text.new("Summary: #{summary}...")]}
  end
end

# ─── 2. Start Everything with One Supervisor ─────────────────────────

IO.puts("=== A2A Supervisor & Registry Demo ===\n")

{:ok, _sup} =
  A2A.AgentSupervisor.start_link(
    agents: [
      Fleet.PricingAgent,
      Fleet.RiskAgent,
      Fleet.SummaryAgent
    ]
  )

IO.puts("Supervisor started with 3 agents + registry\n")

# ─── 3. Discover Agents via Registry ─────────────────────────────────

IO.puts("--- All Registered Agents ---")

for {mod, card} <- A2A.Registry.all(A2A.Registry) do
  tags =
    card.skills
    |> Enum.flat_map(& &1.tags)
    |> Enum.join(", ")

  IO.puts("  #{card.name} (#{inspect(mod)}) — #{card.description}")
  IO.puts("    tags: [#{tags}]")
end

IO.puts("")

# ─── 4. Skill-Based Discovery ────────────────────────────────────────

IO.puts("--- Find Agents by Skill ---")

finance_agents = A2A.Registry.find_by_skill(A2A.Registry, "finance")
IO.puts("  Agents with 'finance' skill: #{inspect(finance_agents)}")

text_agents = A2A.Registry.find_by_skill(A2A.Registry, "text")
IO.puts("  Agents with 'text' skill:    #{inspect(text_agents)}")

risk_agents = A2A.Registry.find_by_skill(A2A.Registry, "risk")
IO.puts("  Agents with 'risk' skill:    #{inspect(risk_agents)}")

IO.puts("")

# ─── 5. Call Discovered Agents ────────────────────────────────────────

IO.puts("--- Call All Finance Agents ---")

for mod <- finance_agents do
  {:ok, card} = A2A.Registry.get(A2A.Registry, mod)
  {:ok, task} = A2A.call(mod, "Widget X-500")

  [artifact | _] = task.artifacts
  [part | _] = artifact.parts

  data =
    case part do
      %A2A.Part.Data{data: d} -> inspect(d)
      %A2A.Part.Text{text: t} -> t
    end

  IO.puts("  #{card.name}: #{data}")
end

IO.puts("")

# ─── 6. Dynamic Registration ─────────────────────────────────────────

IO.puts("--- Dynamic Registration ---")

IO.puts("  Before: #{length(A2A.Registry.all(A2A.Registry))} agents")

# Register a new card without starting an agent process
A2A.Registry.register(A2A.Registry, Fleet.PricingAgent, %{
  Fleet.PricingAgent.agent_card()
  | name: "pricing-v2",
    description: "Updated pricing with discount support"
})

{:ok, updated} = A2A.Registry.get(A2A.Registry, Fleet.PricingAgent)
IO.puts("  Updated pricing card: #{updated.name} — #{updated.description}")

# Unregister
A2A.Registry.unregister(A2A.Registry, Fleet.SummaryAgent)
IO.puts("  Unregistered SummaryAgent")
IO.puts("  After:  #{length(A2A.Registry.all(A2A.Registry))} agents")

IO.puts("")

# ─── 7. Orchestration Pattern ────────────────────────────────────────

IO.puts("--- Orchestration: Route by Skill ---")

# A simple orchestrator that finds the right agent by skill tag
dispatch = fn message, skill_tag ->
  case A2A.Registry.find_by_skill(A2A.Registry, skill_tag) do
    [agent | _] ->
      {:ok, card} = A2A.Registry.get(A2A.Registry, agent)
      {:ok, task} = A2A.call(agent, message)
      IO.puts("  Routed to #{card.name}: #{task.status.state}")
      {:ok, task}

    [] ->
      IO.puts("  No agent found for skill '#{skill_tag}'")
      {:error, :no_agent}
  end
end

dispatch.("Evaluate order #1234", "risk")
dispatch.("How much for Widget Y?", "pricing")

IO.puts("")
IO.puts("Done!")
