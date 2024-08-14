defmodule Context do
  @appkey {Context, :current_app}
  def set_current_app(uuid) do
    ProcDict.put(@appkey, uuid)
  end

  def current_app do
    ProcDict.get_with_ancestors(@appkey)
  end
end
