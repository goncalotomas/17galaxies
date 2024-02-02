defmodule Galaxies.Planets.Events.BuildingConstructionComplete do
  @behaviour Galaxies.Planets.Events

  import Ecto.Query

  alias Galaxies.Repo
  alias Galaxies.{Building, Planet, PlanetBuilding}

  def process(planet, %Galaxies.Planets.PlanetEvent{
        planet_id: planet_id,
        data: %{"building_id" => building_id, "level" => level},
        completed_at: completed_at
      }) do
    # update planet_building row itself
    from(pb in PlanetBuilding,
      where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
      update: [
        set: [
          is_upgrading: false,
          upgrade_finished_at: nil,
          current_level: ^level,
          updated_at: ^completed_at
        ]
      ]
    )
    |> Repo.update_all([])

    planet = Repo.preload(planet, buildings: :building)
    # update planet: increase used planetary fields and additionally:
    # terraformer: increase total planetary fields
    # metal, crystal or deuterium mine: produce resources from planet.updated_at to completed_at
    planet_building =
      Enum.find(planet.buildings, fn planet_building ->
        planet_building.building_id == building_id
      end)

    changeset_attrs =
      %{used_fields: planet.used_fields + 1}
      |> Map.merge(terraformer_attrs(planet_building.building.name, level))
      # TODO we need to always update resources, not just when upgrading a mine
      # since we are using Repo.update, the updated_at field will be overwritten,
      # and the mine production from updated_at to completed_at for non-mine upgrades will be lost.
      |> Map.merge(mine_production_attrs(planet_building.building.name, planet, completed_at))


    Repo.update!(Planet.building_construction_complete_changeset(planet, changeset_attrs))
  end

  defp terraformer_attrs("Terraformer", level),
    do: %{total_fields: Building.terraformer_extra_fields(level)}

  defp terraformer_attrs(_building, _level), do: %{}

  defp mine_production_attrs(building, planet, completed_at)
       when building in ["Metal Mine", "Crystal Mine", "Deuterium Refinery"] do
    duration_milliseconds = abs(DateTime.diff(completed_at, planet.updated_at, :millisecond))
    dbg(duration_milliseconds)

    {metal, crystal, deuterium} =
      Galaxies.Planets.Production.resources_produced(
        planet.buildings,
        duration_milliseconds
      )

    %{
      metal_units: planet.metal_units + metal,
      crystal_units: planet.crystal_units + crystal,
      deuterium_units: planet.deuterium_units + deuterium
    }
  end

  defp mine_production_attrs(_building, _planet, _completed_at), do: %{}
end
