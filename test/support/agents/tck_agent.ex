defmodule A2A.Test.TCKAgent do
  @moduledoc false
  use A2A.Agent,
    name: "tck-agent",
    description: "A2A TCK compliance verification agent",
    version: "1.0.0",
    skills: [
      %{
        id: "tck",
        name: "TCK",
        description: "Handles TCK compliance verification messages",
        tags: ["a2a", "compliance"]
      }
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""

    cond do
      String.contains?(text, "need input") ->
        {:input_required, [A2A.Part.Text.new("Please provide additional input")]}

      true ->
        parts = [A2A.Part.Text.new("TCK response: #{text}")]
        {:stream, Stream.concat([parts])}
    end
  end

  @impl A2A.Agent
  def handle_cancel(_context), do: :ok
end
