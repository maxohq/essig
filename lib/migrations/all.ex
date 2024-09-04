defmodule Migrations.All do
  @moduledoc """
  We explicitly list here all the migration modules
  """
  def modules do
    [
      {2024_0824_120000, Migrations.Migration001},
      {2024_0904_112600, Migrations.Migration002},
      {2024_0904_114100, Migrations.Migration003}
    ]
  end
end
