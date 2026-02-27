defmodule A2A.Test.MultiTurnAgent do
  @moduledoc false
  use A2A.Agent,
    name: "multi-turn",
    description: "Agent that requires multiple turns",
    skills: [
      %{id: "order", name: "Order", description: "Takes orders", tags: ["test"]}
    ]

  @impl A2A.Agent
  def handle_message(message, context) do
    text = A2A.Message.text(message) || ""

    if length(context.history) < 2 do
      {:input_required, [A2A.Part.Text.new("What size?")]}
    else
      {:reply, [A2A.Part.Text.new("Order confirmed: #{text}")]}
    end
  end
end
