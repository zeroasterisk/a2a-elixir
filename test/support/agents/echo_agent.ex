defmodule A2A.Test.EchoAgent do
  @moduledoc false
  use A2A.Agent,
    name: "echo",
    description: "Echoes messages back",
    skills: [
      %{id: "echo", name: "Echo", description: "Echoes input", tags: ["test"]}
    ]

  @impl A2A.Agent
  def handle_message(message, _context) do
    text = A2A.Message.text(message) || ""
    {:reply, [A2A.Part.Text.new(text)]}
  end
end
