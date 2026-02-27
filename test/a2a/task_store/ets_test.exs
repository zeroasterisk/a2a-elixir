defmodule A2A.TaskStore.ETSTest do
  use ExUnit.Case, async: true

  alias A2A.TaskStore.ETS
  alias A2A.Task

  setup do
    table = :"ets_store_#{System.unique_integer([:positive])}"
    start_supervised!({ETS, name: table})
    %{table: table}
  end

  describe "put/2 and get/2" do
    test "stores and retrieves a task", %{table: table} do
      task = Task.new(id: "tsk-1")
      assert :ok = ETS.put(table, task)
      assert {:ok, ^task} = ETS.get(table, "tsk-1")
    end

    test "updates an existing task", %{table: table} do
      task = Task.new(id: "tsk-2")
      ETS.put(table, task)

      updated = %{task | metadata: %{updated: true}}
      ETS.put(table, updated)

      assert {:ok, %{metadata: %{updated: true}}} = ETS.get(table, "tsk-2")
    end
  end

  describe "get/2" do
    test "returns error for missing task", %{table: table} do
      assert {:error, :not_found} = ETS.get(table, "tsk-missing")
    end
  end

  describe "delete/2" do
    test "removes a task", %{table: table} do
      task = Task.new(id: "tsk-del")
      ETS.put(table, task)
      assert :ok = ETS.delete(table, "tsk-del")
      assert {:error, :not_found} = ETS.get(table, "tsk-del")
    end

    test "deleting a non-existent task is a no-op", %{table: table} do
      assert :ok = ETS.delete(table, "tsk-nope")
    end
  end

  describe "list/2" do
    test "lists tasks by context_id", %{table: table} do
      t1 = Task.new(id: "tsk-a", context_id: "ctx-1")
      t2 = Task.new(id: "tsk-b", context_id: "ctx-1")
      t3 = Task.new(id: "tsk-c", context_id: "ctx-2")

      ETS.put(table, t1)
      ETS.put(table, t2)
      ETS.put(table, t3)

      assert {:ok, tasks} = ETS.list(table, "ctx-1")
      ids = Enum.map(tasks, & &1.id) |> Enum.sort()
      assert ids == ["tsk-a", "tsk-b"]
    end

    test "returns empty list for unknown context", %{table: table} do
      assert {:ok, []} = ETS.list(table, "ctx-unknown")
    end
  end
end
