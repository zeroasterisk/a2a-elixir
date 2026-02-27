defmodule A2A.TaskTest do
  use ExUnit.Case, async: true

  alias A2A.Task
  alias A2A.Task.Status

  describe "Task.new/0" do
    test "creates a task in submitted state" do
      task = Task.new()
      assert String.starts_with?(task.id, "tsk-")
      assert task.status.state == :submitted
      assert task.history == []
      assert task.artifacts == []
      assert task.metadata == %{}
    end

    test "accepts options" do
      task = Task.new(id: "tsk-custom", context_id: "ctx-1", metadata: %{x: 1})
      assert task.id == "tsk-custom"
      assert task.context_id == "ctx-1"
      assert task.metadata == %{x: 1}
    end
  end

  describe "Task.terminal?/1" do
    test "completed is terminal" do
      task = %Task{id: "t", status: Status.new(:completed)}
      assert Task.terminal?(task)
    end

    test "canceled is terminal" do
      task = %Task{id: "t", status: Status.new(:canceled)}
      assert Task.terminal?(task)
    end

    test "failed is terminal" do
      task = %Task{id: "t", status: Status.new(:failed)}
      assert Task.terminal?(task)
    end

    test "submitted is not terminal" do
      task = %Task{id: "t", status: Status.new(:submitted)}
      refute Task.terminal?(task)
    end

    test "working is not terminal" do
      task = %Task{id: "t", status: Status.new(:working)}
      refute Task.terminal?(task)
    end

    test "input_required is not terminal" do
      task = %Task{id: "t", status: Status.new(:input_required)}
      refute Task.terminal?(task)
    end
  end

  describe "Status.new/1" do
    test "creates a status with timestamp" do
      status = Status.new(:working)
      assert status.state == :working
      assert status.message == nil
      assert %DateTime{} = status.timestamp
    end

    test "accepts an optional message" do
      msg = A2A.Message.new_agent("working on it")
      status = Status.new(:working, msg)
      assert status.message == msg
    end
  end
end
