defmodule A2A.RegistryTest do
  use ExUnit.Case, async: true

  alias A2A.Registry

  setup do
    name = :"registry_#{System.unique_integer([:positive])}"
    {:ok, _pid} = Registry.start_link(name: name)
    %{registry: name}
  end

  describe "register/3 and get/2" do
    test "round-trip stores and retrieves a card", %{registry: reg} do
      card = A2A.Test.EchoAgent.agent_card()
      assert :ok = Registry.register(reg, A2A.Test.EchoAgent, card)
      assert {:ok, ^card} = Registry.get(reg, A2A.Test.EchoAgent)
    end

    test "re-registration updates the card", %{registry: reg} do
      card1 = %{name: "v1", description: "", version: "1.0", skills: [], opts: []}
      card2 = %{name: "v2", description: "", version: "2.0", skills: [], opts: []}

      :ok = Registry.register(reg, A2A.Test.EchoAgent, card1)
      :ok = Registry.register(reg, A2A.Test.EchoAgent, card2)

      assert {:ok, ^card2} = Registry.get(reg, A2A.Test.EchoAgent)
    end
  end

  describe "get/2" do
    test "returns {:error, :not_found} for unknown module", %{registry: reg} do
      assert {:error, :not_found} = Registry.get(reg, UnknownModule)
    end
  end

  describe "unregister/2" do
    test "removes an entry", %{registry: reg} do
      card = A2A.Test.EchoAgent.agent_card()
      :ok = Registry.register(reg, A2A.Test.EchoAgent, card)
      :ok = Registry.unregister(reg, A2A.Test.EchoAgent)

      assert {:error, :not_found} = Registry.get(reg, A2A.Test.EchoAgent)
    end
  end

  describe "find_by_skill/2" do
    test "matches agents by skill tag", %{registry: reg} do
      card = A2A.Test.EchoAgent.agent_card()
      :ok = Registry.register(reg, A2A.Test.EchoAgent, card)

      assert [A2A.Test.EchoAgent] = Registry.find_by_skill(reg, "test")
    end

    test "returns empty list when no agents match", %{registry: reg} do
      card = A2A.Test.EchoAgent.agent_card()
      :ok = Registry.register(reg, A2A.Test.EchoAgent, card)

      assert [] = Registry.find_by_skill(reg, "nonexistent")
    end
  end

  describe "all/1" do
    test "returns all entries", %{registry: reg} do
      echo_card = A2A.Test.EchoAgent.agent_card()
      stream_card = A2A.Test.StreamAgent.agent_card()

      :ok = Registry.register(reg, A2A.Test.EchoAgent, echo_card)
      :ok = Registry.register(reg, A2A.Test.StreamAgent, stream_card)

      entries = Registry.all(reg)
      assert length(entries) == 2

      modules = Enum.map(entries, fn {mod, _card} -> mod end)
      assert A2A.Test.EchoAgent in modules
      assert A2A.Test.StreamAgent in modules
    end

    test "returns empty list when empty", %{registry: reg} do
      assert [] = Registry.all(reg)
    end
  end

  describe "pre-populated from :agents option" do
    test "populates registry by calling agent_card/0 on each module" do
      name = :"prepop_#{System.unique_integer([:positive])}"

      {:ok, _pid} =
        Registry.start_link(
          name: name,
          agents: [A2A.Test.EchoAgent, A2A.Test.StreamAgent]
        )

      assert {:ok, _card} = Registry.get(name, A2A.Test.EchoAgent)
      assert {:ok, _card} = Registry.get(name, A2A.Test.StreamAgent)
      assert length(Registry.all(name)) == 2
    end
  end
end
