defmodule A2A.Test.ErrorAgent do
  @moduledoc false
  use A2A.Agent,
    name: "error-agent",
    description: "Always fails",
    skills: []

  @impl A2A.Agent
  def handle_message(_message, _context) do
    {:error, :something_went_wrong}
  end
end
