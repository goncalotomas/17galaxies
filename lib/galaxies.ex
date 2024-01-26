defmodule Galaxies do
  @moduledoc """
  Galaxies keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @default_attrs %{
    universe_speed: 100
  }

  def calc_upgrade_cost(formula, level, attrs \\ %{}) do
    [metal_cost, crystal_cost, deuterium_cost, energy_cost] =
      formula
      |> String.split("$")
      |> Enum.map(fn expression ->
        {:ok, result} =
          Abacus.eval(expression, Map.merge(@default_attrs, Map.put(attrs, "level", level)))

        ceil(result)
      end)

    {metal_cost, crystal_cost, deuterium_cost, energy_cost}
  end
end
