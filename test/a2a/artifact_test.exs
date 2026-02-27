defmodule A2A.ArtifactTest do
  use ExUnit.Case, async: true

  alias A2A.Artifact
  alias A2A.Part

  describe "new/1" do
    test "creates an artifact with parts" do
      parts = [Part.Text.new("result")]
      artifact = Artifact.new(parts)
      assert String.starts_with?(artifact.artifact_id, "art-")
      assert artifact.parts == parts
      assert artifact.metadata == %{}
    end

    test "accepts optional name and description" do
      artifact = Artifact.new([Part.Text.new("x")], name: "report", description: "A report")
      assert artifact.name == "report"
      assert artifact.description == "A report"
    end

    test "accepts metadata" do
      artifact = Artifact.new([Part.Text.new("x")], metadata: %{format: "pdf"})
      assert artifact.metadata == %{format: "pdf"}
    end
  end
end
