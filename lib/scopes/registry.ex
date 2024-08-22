defmodule Essig.Scopes.Registry do
  def get(scope) do
    case Registry.lookup(__MODULE__, scope) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def keys do
    Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
  end

  def all do
    Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.sort()
  end
end
