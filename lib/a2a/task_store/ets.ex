defmodule A2A.TaskStore.ETS do
  @moduledoc """
  ETS-backed task store implementation.

  Uses a named ETS table for storage. The store reference is the table name atom.
  Suitable for single-node, concurrent access.

  ## Usage

      {:ok, _pid} = A2A.TaskStore.ETS.start_link(name: :my_tasks)
      :ok = A2A.TaskStore.ETS.put(:my_tasks, task)
      {:ok, task} = A2A.TaskStore.ETS.get(:my_tasks, "tsk-abc123")

  ## With an Agent

      MyAgent.start_link(task_store: {A2A.TaskStore.ETS, :my_tasks})
  """

  use GenServer

  @behaviour A2A.TaskStore

  @doc """
  Starts the ETS task store process which creates the underlying table.

  ## Options

  - `:name` — the table/process name (required)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @impl A2A.TaskStore
  def get(table, task_id) do
    case :ets.lookup(table, task_id) do
      [{^task_id, task}] -> {:ok, task}
      [] -> {:error, :not_found}
    end
  end

  @impl A2A.TaskStore
  def put(table, %A2A.Task{} = task) do
    :ets.insert(table, {task.id, task})
    :ok
  end

  @impl A2A.TaskStore
  def delete(table, task_id) do
    :ets.delete(table, task_id)
    :ok
  end

  @impl A2A.TaskStore
  def list(table, context_id) do
    tasks =
      :ets.tab2list(table)
      |> Enum.filter(fn {_id, task} -> task.context_id == context_id end)
      |> Enum.map(fn {_id, task} -> task end)

    {:ok, tasks}
  end

  # --- GenServer callbacks ---

  @impl GenServer
  def init(name) do
    table = :ets.new(name, [:named_table, :public, :set, read_concurrency: true])
    {:ok, table}
  end
end
