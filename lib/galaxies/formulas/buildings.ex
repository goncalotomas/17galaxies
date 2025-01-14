defmodule Galaxies.Formulas.Buildings do
  @moduledoc """
  Formulas for buildings.
  """

  @universe_speed 100

  @default_attrs %{
    universe_speed: @universe_speed
  }

  def construction_time_seconds(building_id, level, robotics_level, nanites_level) do
    {metal, crystal, _deuterium, _energy} = upgrade_cost(building_id, level)

    num = metal + crystal
    denomenator = 2500 * (1 + robotics_level) * :math.pow(2, nanites_level) * @universe_speed

    ceil(num / denomenator)
  end

  def upgrade_cost(building_id, level) do
    building = Galaxies.Cached.Buildings.get_building_by_id(building_id)

    [metal_cost, crystal_cost, deuterium_cost, energy_cost] =
      building.upgrade_cost_formula
      |> String.split("$")
      |> Enum.map(fn expression ->
        {:ok, result} =
          Abacus.eval(expression, Map.merge(@default_attrs, %{"level" => level}))

        ceil(result)
      end)

    {metal_cost, crystal_cost, deuterium_cost, energy_cost}
  end
end
