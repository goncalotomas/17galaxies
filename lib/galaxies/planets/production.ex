defmodule Galaxies.Planets.Production do
  @universe_speed 1000
  @milliseconds_per_hour 3600 * 1000

  @metal_mine_building_id 1
  @crystal_mine_building_id 2
  @deuterium_synth_building_id 3

  def resources_produced(planet_buildings, duration_millisecond) do
    # TODO: Expand to consider resources_produced = raw_mine_production - deut consumption * available energy
    # TODO: Expand to consider player technologies
    # TODO: Expand to include planet avg/max temperature
    {metal_level, crystal_level, deuterium_level} = mine_levels(planet_buildings)

    {
      duration_millisecond * metal_mine_production(metal_level) / @milliseconds_per_hour,
      duration_millisecond * crystal_mine_production(crystal_level) / @milliseconds_per_hour,
      duration_millisecond * deuterium_mine_production(deuterium_level) / @milliseconds_per_hour
    }
  end

  defp mine_levels(planet_buildings), do: mine_levels({nil, nil, nil}, planet_buildings)

  defp mine_levels({m, c, d}, _buildings) when not is_nil(m) and not is_nil(c) and not is_nil(d),
    do: {m, c, d}

  defp mine_levels({m, c, d}, [planet_building | t]) do
    cond do
      planet_building.building_id == @metal_mine_building_id ->
        mine_levels({planet_building.level, c, d}, t)

      planet_building.building_id == @crystal_mine_building_id ->
        mine_levels({m, planet_building.level, d}, t)

      planet_building.building_id == @deuterium_synth_building_id ->
        mine_levels({m, c, planet_building.level}, t)

      true ->
        mine_levels({m, c, d}, t)
    end
  end

  defp metal_mine_production(level) do
    30 * @universe_speed * level * :math.pow(1.1, level) + 30 * @universe_speed
  end

  defp crystal_mine_production(level) do
    20 * @universe_speed * level * :math.pow(1.1, level) + 15 * @universe_speed
  end

  defp deuterium_mine_production(level, avg_temp \\ 20) do
    @universe_speed * 10 * level * :math.pow(1.1, level) * (1.36 - 0.004 * avg_temp)
  end
end
