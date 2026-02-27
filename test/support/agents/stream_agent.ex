defmodule A2A.Test.StreamAgent do
  @moduledoc false
  use A2A.Agent,
    name: "stream-agent",
    description: "Streams parts back",
    skills: []

  @impl A2A.Agent
  def handle_message(_message, _context) do
    stream =
      Stream.map(1..3, fn i ->
        A2A.Part.Text.new("chunk #{i}")
      end)

    {:stream, stream}
  end
end
