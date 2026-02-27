defmodule A2A.TaskStore do
  @moduledoc """
  Behaviour for pluggable task persistence.

  Implementations store and retrieve `A2A.Task` structs. Each callback
  receives a store reference (opaque term) that the implementation uses
  to locate its storage — e.g., an ETS table name or a connection PID.

  ## Implementing a Custom Store

      defmodule MyApp.RedisTaskStore do
        @behaviour A2A.TaskStore

        @impl true
        def get(conn, task_id) do
          # ...
        end

        # ... other callbacks
      end

  ## Configuring an Agent with a Store

      MyAgent.start_link(task_store: {A2A.TaskStore.ETS, :my_tasks})
  """

  @type ref :: term()

  @doc """
  Retrieves a task by ID.
  """
  @callback get(ref(), task_id :: String.t()) :: {:ok, A2A.Task.t()} | {:error, :not_found}

  @doc """
  Stores or updates a task.
  """
  @callback put(ref(), A2A.Task.t()) :: :ok | {:error, term()}

  @doc """
  Deletes a task by ID.
  """
  @callback delete(ref(), task_id :: String.t()) :: :ok | {:error, term()}

  @doc """
  Lists all tasks for a given context ID.
  """
  @callback list(ref(), context_id :: String.t()) :: {:ok, [A2A.Task.t()]}
end
