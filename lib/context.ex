defmodule Essig.Context do
  alias Essig.Helpers.ProcDict
  @appkey {Context, :current_scope}
  def set_current_scope(uuid) do
    ProcDict.put(@appkey, uuid)
  end

  def current_scope do
    ProcDict.get_with_ancestors(@appkey)
  end

  def assert_current_scope! do
    current_scope() ||
      raise "Missing current_scope, set via: Essig.Context.set_current_scope(uuid)!"
  end

  @metakey {Context, :current_meta}
  def set_current_meta(meta) do
    ProcDict.put(@metakey, meta)
  end

  def current_meta do
    ProcDict.get_with_ancestors(@metakey) || %{}
  end
end
