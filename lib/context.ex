defmodule Essig.Context do
  alias Essig.Helpers.ProcessTree
  @appkey {Context, :current_scope}
  def set_current_scope(uuid) do
    Process.put(@appkey, uuid)
  end

  def current_scope do
    ProcessTree.get(@appkey, default: "00000000-0000-0000-0000-000000000001")
  end

  def assert_current_scope! do
    current_scope() ||
      raise "Missing current_scope, set via: Essig.Context.set_current_scope(uuid)!"
  end

  @metakey {Context, :current_meta}
  def set_current_meta(meta) do
    Process.put(@metakey, meta)
  end

  def current_meta do
    ProcessTree.get(@metakey) || %{}
  end
end
