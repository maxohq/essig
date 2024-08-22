defmodule Migrations.All do
  @moduledoc """
  We explicitly list here all the migration modules
  """
  def modules do
    [
      {20_240_824_120_000, Migrations.Migration001}
    ]
  end
end
