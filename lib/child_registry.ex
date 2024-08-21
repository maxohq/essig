# defmodule ChildRegistry do
#   require Logger

#   def register({scope_name, module}, pid) do
#     Registry.register(__MODULE__, {scope_name, module}, pid)
#   end

#   def get(module) do
#     scope_name = Context.current_scope()

#     case Registry.lookup(__MODULE__, {scope_name, module}) do
#       [{pid, _}] -> pid
#       [] -> nil
#     end
#   end

#   def keys do
#     Registry.select(__MODULE__, [{{:"$1", :_, :_}, [], [:"$1"]}]) |> Enum.sort()
#   end

#   def all do
#     Registry.select(__MODULE__, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
#     |> Enum.sort()
#   end
# end
