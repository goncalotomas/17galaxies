defmodule Galaxies.Planets.Events.ConstructionComplete do
  alias Galaxies.PlayerResearch
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.PlanetBuilding
  alias Galaxies.Planet
  alias Galaxies.Formulas.Buildings
  alias Galaxies.Formulas.Buildings.Terraformer
  alias Galaxies.Planets.Production
  alias Galaxies.Repo
  alias Galaxies.Planets.Events.BuildingEvent

  import Ecto.Query
  import Ecto.Changeset

  @behaviour Galaxies.Planets.Event

  @terraformer_building_id 13
  @energy_tech_id 3

  def process(%PlanetEvent{type: :construction_complete} = event, planet_id) do
    %{
      building_event: %BuildingEvent{building_id: building_id, demolish: demolish}
    } = event

    processed_at = DateTime.utc_now(:microsecond)

    event_update_params = %{
      is_processed: true,
      completed_at: processed_at
    }

    Ecto.Multi.new()
    |> Ecto.Multi.run(:upgrade_building_increment_fields, fn repo, _changes ->
      level_increment = if demolish, do: -1, else: 1

      from(pb in PlanetBuilding,
        where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
        update: [inc: [level: ^level_increment]]
      )
      |> repo.update_all([])

      if not Galaxies.Buildings.production_building?(building_id) do
        total_fields_increment =
          if building_id == @terraformer_building_id,
            do: Terraformer.field_increase(level_increment),
            else: 0

        from(p in Planet,
          where: p.id == ^planet_id,
          update: [inc: [used_fields: ^level_increment, total_fields: ^total_fields_increment]]
        )
        |> repo.update_all([])
      end

      {:ok, nil}
    end)
    |> Ecto.Multi.run(:maybe_produce_resources_on_planet, fn repo, _changes ->
      # if the building that was upgraded was a production related building, we need to produce resources
      # on the planet, since all production from this moment onwards will take place at a higher/lower rate.

      if Galaxies.Buildings.production_building?(building_id) do
        planet = repo.one!(from p in Planet, where: p.id == ^planet_id, preload: [:buildings])

        # we produce since the last update and not since the start of the construction
        # because many events can happen since a building starts construction
        time_delta = DateTime.diff(processed_at, planet.updated_at, :millisecond)

        {metal, crystal, deuterium} =
          Production.resources_produced(planet.buildings, time_delta)

        # energy delta calculation
        planet_building = Enum.find(planet.buildings, fn pb -> pb.building_id == building_id end)
        level = planet_building.level
        resource_building? = Galaxies.Buildings.resource_production_building?(building_id)

        l1 = level
        l2 = if demolish, do: level + 1, else: level - 1

        energy_changes =
          if resource_building? do
            # it's a mine
            energy_delta =
              building_id
              |> energy_consumption_delta(l1, l2)
              |> then(fn delta -> if demolish, do: delta, else: -delta end)

            [available_energy: planet.available_energy + energy_delta]
          else
            # it's an energy production building
            energy_tech_level =
              repo.one!(
                from pt in PlayerResearch,
                  where: pt.player_id == ^planet.player_id and pt.research_id == ^@energy_tech_id
              ).level

            energy_delta =
              building_id
              |> energy_production_delta(l1, l2, energy_tech_level)
              |> then(fn delta -> if demolish, do: -delta, else: delta end)

            [
              available_energy: planet.available_energy + energy_delta,
              total_energy: planet.total_energy + energy_delta
            ]
          end

        new_used_fields = if demolish, do: planet.used_fields - 1, else: planet.used_fields + 1

        planet =
          planet
          |> change(
            Keyword.merge(
              [
                metal_units: planet.metal_units + metal,
                crystal_units: planet.crystal_units + crystal,
                deuterium_units: planet.deuterium_units + deuterium,
                used_fields: new_used_fields
              ],
              energy_changes
            )
          )
          |> repo.update!()

        {:ok, planet}
      else
        {:ok, nil}
      end
    end)
    |> Ecto.Multi.update(:update_event, PlanetEvent.process_changeset(event, event_update_params))
    |> Ecto.Multi.run(:start_next_construction, fn repo,
                                                   %{maybe_produce_resources_on_planet: planet} ->
      # fetch all events and start the first one that meets all prerequisites to be started, if any
      next_events =
        repo.all(
          from e in PlanetEvent,
            where:
              e.planet_id == ^planet_id and e.type == ^:construction_complete and
                e.is_processed == false and e.is_cancelled == false,
            order_by: [asc: e.inserted_at]
        )

      if Enum.empty?(next_events) do
        {:ok, nil}
      else
        planet =
          if is_nil(planet) do
            repo.one!(from p in Planet, where: p.id == ^planet_id, preload: [:buildings])
          else
            planet
          end

        {events_to_cancel, event_to_start} = select_next_event(next_events, planet)

        if not Enum.empty?(events_to_cancel) do
          event_ids = Enum.map(events_to_cancel, & &1.id)

          from(e in PlanetEvent,
            where: e.id in ^event_ids,
            update: [set: [is_cancelled: true]]
          )
          |> repo.update_all([])
        end

        if event_to_start do
          completed_at =
            processed_at
            |> DateTime.add(event_to_start.building_event.duration_seconds, :second)

          event_to_start =
            event_to_start
            |> change(started_at: processed_at, completed_at: completed_at)
            |> repo.update!()

          level =
            Enum.find(planet.buildings, fn planet_building ->
              planet_building.building_id == event_to_start.building_event.building_id
            end).level

          building =
            Galaxies.Cached.Buildings.get_building_by_id(
              event_to_start.building_event.building_id
            )

          # Energy is only deducted after the building is fully constructed
          # TODO add support for demolish in the upgrade cost formula
          {metal, crystal, deuterium, _energy} =
            Galaxies.calc_upgrade_cost(
              building.upgrade_cost_formula,
              level + 1
            )

          planet
          |> change(
            metal_units: planet.metal_units - metal,
            crystal_units: planet.crystal_units - crystal,
            deuterium_units: planet.deuterium_units - deuterium
          )
          |> repo.update!()

          {:ok, event_to_start}
        else
          {:ok, nil}
        end
      end
    end)
    |> Repo.transaction()
  end

  defp select_next_event(next_events, planet) do
    Enum.reduce_while(next_events, {[], nil}, fn event, {cancelled, nil} ->
      %{
        building_event: %BuildingEvent{building_id: building_id, demolish: demolish}
      } = event

      level =
        Enum.find(planet.buildings, fn planet_building ->
          planet_building.building_id == building_id
        end).level

      building = Galaxies.Cached.Buildings.get_building_by_id(building_id)

      next_level = if demolish, do: level - 1, else: level + 1

      {metal, crystal, deuterium, _energy} =
        Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, next_level)

      if planet.metal_units >= metal and planet.crystal_units >= crystal and
           planet.deuterium_units >= deuterium do
        # TODO check for prerequisites
        {:halt, {cancelled, event}}
      else
        {:cont, {[event | cancelled], nil}}
      end
    end)
  end

  defp energy_production_delta(building_id, l1, l2, energy_tech_level) do
    p1 = Buildings.energy_production(building_id, l1, energy_tech_level)
    p2 = Buildings.energy_production(building_id, l2, energy_tech_level)

    abs(p2 - p1)
  end

  defp energy_consumption_delta(building_id, l1, l2) do
    p1 = Buildings.energy_consumption(building_id, l1)
    p2 = Buildings.energy_consumption(building_id, l2)

    abs(p2 - p1)
  end
end
