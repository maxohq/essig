defmodule Essig.Helpers.ResponseWrapper do
  def cast(pid, args) do
    if is_pid(pid) do
      GenServer.cast(pid, args)
    else
      {:error, :no_process}
    end
  end

  def call(pid, args) do
    if is_pid(pid) do
      GenServer.call(pid, args)
    else
      {:error, :no_process}
    end
  end
end
