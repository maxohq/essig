defmodule Context do
  @appkey {Context, :current_scope}
  def set_current_scope(uuid) do
    ProcDict.put(@appkey, uuid)
  end

  def current_scope do
    ProcDict.get_with_ancestors(@appkey)
  end

  def assert_current_scope! do
    current_scope() || raise "Missing current_scope, set via: Context.set_current_scope(uuid)!"
  end
end
