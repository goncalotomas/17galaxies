defmodule Galaxies.Formulas.Buildings do
  @moduledoc """
  Formulas for buildings.
  """

  @universe_speed 100

  @default_attrs %{
    universe_speed: @universe_speed
  }

  @metal_mine_building_id 1
  @crystal_mine_building_id 2
  @deuterium_synthesizer_building_id 3
  @solar_plant_building_id 4
  @fusion_reactor_building_id 12

  @doc """
  Returns the total energy consumption of a particular building at a given level.
  """
  def energy_consumption(@metal_mine_building_id, level),
    do: trunc(10 * level * :math.pow(1.1, level))

  def energy_consumption(@crystal_mine_building_id, level),
    do: trunc(10 * level * :math.pow(1.1, level))

  def energy_consumption(@deuterium_synthesizer_building_id, level),
    do: trunc(20 * level * :math.pow(1.1, level))

  def energy_consumption(_building_id, _level), do: 0

  @doc """
  Returns the total energy production of a particular building at a given level.
  """
  def energy_production(@solar_plant_building_id, level, _energy_level),
    do: trunc(20 * level * :math.pow(1.1, level))

  def energy_production(@fusion_reactor_building_id, level, energy_level),
    do: trunc(30 * level * :math.pow(1.05 + energy_level * 0.01, level))

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
