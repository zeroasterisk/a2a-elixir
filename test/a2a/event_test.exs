defmodule A2A.EventTest do
  use ExUnit.Case, async: true

  alias A2A.Event.{StatusUpdate, ArtifactUpdate}
  alias A2A.Task.Status
  alias A2A.Artifact
  alias A2A.Part

  describe "StatusUpdate" do
    test "new/2 creates a status update with defaults" do
      status = Status.new(:working)
      event = StatusUpdate.new("tsk-1", status)

      assert %StatusUpdate{
               task_id: "tsk-1",
               context_id: nil,
               status: ^status,
               final: false,
               metadata: %{}
             } = event
    end

    test "new/3 accepts options" do
      status = Status.new(:completed)

      event =
        StatusUpdate.new("tsk-1", status,
          context_id: "ctx-1",
          final: true,
          metadata: %{source: "test"}
        )

      assert event.context_id == "ctx-1"
      assert event.final == true
      assert event.metadata == %{source: "test"}
    end
  end

  describe "ArtifactUpdate" do
    test "new/2 creates an artifact update with defaults" do
      artifact = Artifact.new([Part.Text.new("result")])
      event = ArtifactUpdate.new("tsk-1", artifact)

      assert %ArtifactUpdate{
               task_id: "tsk-1",
               context_id: nil,
               artifact: ^artifact,
               append: nil,
               last_chunk: nil,
               metadata: %{}
             } = event
    end

    test "new/3 accepts options" do
      artifact = Artifact.new([Part.Text.new("chunk")])

      event =
        ArtifactUpdate.new("tsk-1", artifact,
          context_id: "ctx-1",
          append: true,
          last_chunk: false,
          metadata: %{seq: 1}
        )

      assert event.context_id == "ctx-1"
      assert event.append == true
      assert event.last_chunk == false
      assert event.metadata == %{seq: 1}
    end
  end
end
