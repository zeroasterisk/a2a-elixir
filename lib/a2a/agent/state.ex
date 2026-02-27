defmodule A2A.Agent.State do
  @moduledoc false

  @type t :: %__MODULE__{
          module: module(),
          tasks: %{String.t() => A2A.Task.t()},
          contexts: %{String.t() => [String.t()]},
          task_store: {module(), A2A.TaskStore.ref()} | nil
        }

  defstruct module: nil,
            tasks: %{},
            contexts: %{},
            task_store: nil

  @doc """
  Transitions a task to a new state, updating the status.
  """
  @spec transition(A2A.Task.t(), A2A.Task.Status.state(), A2A.Message.t() | nil) ::
          A2A.Task.t()
  def transition(task, new_state, message \\ nil) do
    %{task | status: A2A.Task.Status.new(new_state, message)}
  end

  @doc """
  Stores a task in the internal state map and optionally in the external store.
  """
  @spec put_task(t(), A2A.Task.t()) :: t()
  def put_task(%{task_store: {mod, ref}} = state, task) do
    mod.put(ref, task)
    %{state | tasks: Map.put(state.tasks, task.id, task)}
  end

  def put_task(state, task) do
    %{state | tasks: Map.put(state.tasks, task.id, task)}
  end

  @doc """
  Retrieves a task, checking the external store first if configured.
  """
  @spec get_task(t(), String.t()) :: {:ok, A2A.Task.t()} | {:error, :not_found}
  def get_task(%{task_store: {mod, ref}} = state, task_id) do
    case Map.fetch(state.tasks, task_id) do
      {:ok, task} -> {:ok, task}
      :error -> mod.get(ref, task_id)
    end
  end

  def get_task(state, task_id) do
    case Map.fetch(state.tasks, task_id) do
      {:ok, task} -> {:ok, task}
      :error -> {:error, :not_found}
    end
  end

  @doc """
  Tracks a task under its context_id.
  """
  @spec track_context(t(), A2A.Task.t()) :: t()
  def track_context(state, %{context_id: nil}), do: state

  def track_context(state, %{context_id: ctx_id, id: task_id}) do
    contexts = Map.update(state.contexts, ctx_id, [task_id], &[task_id | &1])
    %{state | contexts: contexts}
  end
end
