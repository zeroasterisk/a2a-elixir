defmodule A2A.PartTest do
  use ExUnit.Case, async: true

  alias A2A.Part
  alias A2A.FileContent

  describe "Part.Text" do
    test "new/1 creates a text part with defaults" do
      part = Part.Text.new("hello")
      assert %Part.Text{text: "hello", metadata: %{}} = part
    end

    test "new/2 accepts metadata" do
      part = Part.Text.new("hello", %{lang: "en"})
      assert part.metadata == %{lang: "en"}
    end
  end

  describe "Part.File" do
    test "new/1 creates a file part" do
      fc = FileContent.from_bytes("data", name: "test.txt")
      part = Part.File.new(fc)
      assert %Part.File{file: ^fc, metadata: %{}} = part
    end

    test "new/2 accepts metadata" do
      fc = FileContent.from_uri("https://example.com/file.pdf")
      part = Part.File.new(fc, %{source: "upload"})
      assert part.metadata == %{source: "upload"}
    end
  end

  describe "Part.Data" do
    test "new/1 creates a data part" do
      part = Part.Data.new(%{key: "value"})
      assert %Part.Data{data: %{key: "value"}, metadata: %{}} = part
    end

    test "new/2 accepts metadata" do
      part = Part.Data.new(%{x: 1}, %{schema: "v1"})
      assert part.metadata == %{schema: "v1"}
    end
  end
end
