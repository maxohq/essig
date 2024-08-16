defmodule Context do
  @appkey {Context, :current_app}
  def set_current_app(uuid) do
    ProcDict.put(@appkey, uuid)
  end

  def current_app do
    ProcDict.get_with_ancestors(@appkey)
  end

  def assert_current_app! do
    current_app() || raise "Missing current_app, set via: Context.set_current_app(uuid)!"
  end
end
