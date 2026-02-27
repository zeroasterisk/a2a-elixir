defmodule A2A.Client.SSETest do
  use ExUnit.Case, async: true

  alias A2A.Client.SSE

  describe "new/0" do
    test "creates empty buffer state" do
      assert %{buffer: ""} = SSE.new()
    end
  end

  describe "feed/2" do
    test "parses a single complete event" do
      state = SSE.new()
      chunk = "data: {\"id\":1}\n\n"

      {events, state} = SSE.feed(state, chunk)

      assert [%{"id" => 1}] = events
      assert state.buffer == ""
    end

    test "parses multiple events in one chunk" do
      state = SSE.new()
      chunk = "data: {\"a\":1}\n\ndata: {\"b\":2}\n\n"

      {events, _state} = SSE.feed(state, chunk)

      assert [%{"a" => 1}, %{"b" => 2}] = events
    end

    test "buffers incomplete events across chunks" do
      state = SSE.new()

      {events, state} = SSE.feed(state, "data: {\"a\":")
      assert events == []

      {events, state} = SSE.feed(state, "1}\n\n")
      assert [%{"a" => 1}] = events
      assert state.buffer == ""
    end

    test "handles events split at boundary" do
      state = SSE.new()

      {events, state} = SSE.feed(state, "data: {\"x\":1}\n")
      assert events == []

      {events, _state} = SSE.feed(state, "\ndata: {\"y\":2}\n\n")
      assert [%{"x" => 1}, %{"y" => 2}] = events
    end

    test "ignores non-data lines" do
      state = SSE.new()
      chunk = "event: update\nid: 42\ndata: {\"val\":true}\nretry: 3000\n\n"

      {events, _state} = SSE.feed(state, chunk)

      assert [%{"val" => true}] = events
    end

    test "skips events with malformed JSON" do
      state = SSE.new()
      chunk = "data: not-json\n\ndata: {\"ok\":true}\n\n"

      {events, _state} = SSE.feed(state, chunk)

      assert [%{"ok" => true}] = events
    end

    test "handles data lines with extra spaces after colon" do
      state = SSE.new()
      chunk = "data:  {\"spaced\":true}\n\n"

      {events, _state} = SSE.feed(state, chunk)

      assert [%{"spaced" => true}] = events
    end

    test "joins multiple data lines in one event" do
      state = SSE.new()

      # Per SSE spec, multi-line data fields get joined with newlines.
      # Our parser concatenates data lines with \n then JSON-decodes.
      # A JSON object on a single data line is the common case for A2A.
      chunk = "data: {\"key\":\ndata: \"value\"}\n\n"

      {events, _state} = SSE.feed(state, chunk)

      # This is valid JSON when joined: {"key":\n"value"}
      # which is actually valid JSON
      assert [%{"key" => "value"}] = events
    end

    test "returns empty list for empty input" do
      state = SSE.new()
      {events, state} = SSE.feed(state, "")
      assert events == []
      assert state.buffer == ""
    end
  end
end
