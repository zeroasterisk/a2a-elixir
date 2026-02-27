defmodule A2A.AgentCardTest do
  use ExUnit.Case, async: true

  alias A2A.AgentCard

  describe "struct" do
    test "creates with required fields" do
      card = %AgentCard{
        name: "test",
        description: "A test agent",
        url: "https://example.com",
        version: "1.0.0",
        skills: [%{id: "s1", name: "Skill", description: "Does things", tags: []}]
      }

      assert card.name == "test"
      assert card.description == "A test agent"
      assert card.url == "https://example.com"
      assert card.version == "1.0.0"
      assert length(card.skills) == 1
    end

    test "has sensible defaults" do
      card = %AgentCard{
        name: "test",
        description: "desc",
        url: "https://example.com",
        version: "1.0.0",
        skills: []
      }

      assert card.capabilities == %{}
      assert card.default_input_modes == ["text/plain"]
      assert card.default_output_modes == ["text/plain"]
      assert card.provider == nil
      assert card.documentation_url == nil
      assert card.icon_url == nil
      assert card.protocol_version == nil
    end

    test "raises when required fields are missing" do
      assert_raise ArgumentError, ~r/name/, fn ->
        struct!(AgentCard, %{description: "x", url: "x", version: "1", skills: []})
      end
    end
  end
end
