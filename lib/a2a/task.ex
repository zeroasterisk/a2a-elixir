defmodule A2A.Task do
  @moduledoc """
  A unit of work managed by an agent runtime.

  Tasks track lifecycle state, message history, and produced artifacts.
  """

  @type state :: A2A.Task.Status.state()

  @type t :: %__MODULE__{
          id: String.t(),
          context_id: String.t() | nil,
          status: A2A.Task.Status.t(),
          history: [A2A.Message.t()],
          artifacts: [A2A.Artifact.t()],
          metadata: map()
        }

  @enforce_keys [:id, :status]
  defstruct [
    :id,
    :context_id,
    :status,
    history: [],
    artifacts: [],
    metadata: %{}
  ]

  @terminal_states [:completed, :canceled, :failed]

  @doc """
  Returns `true` if the task is in a terminal state.
  """
  @spec terminal?(t()) :: boolean()
  def terminal?(%__MODULE__{status: %A2A.Task.Status{state: state}}) do
    state in @terminal_states
  end

  @doc """
  Creates a new task in the `:submitted` state.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      id: Keyword.get_lazy(opts, :id, fn -> A2A.ID.generate("tsk") end),
      context_id: Keyword.get(opts, :context_id),
      status: A2A.Task.Status.new(:submitted),
      history: Keyword.get(opts, :history, []),
      artifacts: Keyword.get(opts, :artifacts, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
