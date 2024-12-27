defmodule Essig.Projections.Data do
  @type t :: %__MODULE__{
          row: map(),
          name: atom() | nil,
          pause_ms: non_neg_integer(),
          store_max_id: non_neg_integer(),
          module: module() | nil,
          private: map()
        }

  defstruct row: %{}, name: nil, pause_ms: 0, store_max_id: 0, module: nil, private: %{}
end
