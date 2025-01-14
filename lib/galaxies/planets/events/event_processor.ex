# defmodule Galaxies.Planets.Events.EventProcessor do
#   @moduledoc """
#   Defines the logic for how to process events on a planet.
#   """
#   alias Galaxies.Formulas.Buildings.Terraformer
#   alias Galaxies.Planets.Production
#   alias Galaxies.Repo
#   alias Galaxies.Planets.Events.BuildingEvent
#   alias Galaxies.Planets.PlanetEvent
#   alias Galaxies.PlanetBuilding
#   alias Galaxies.Planet

#   import Ecto.Query
#   import Ecto.Changeset

#   @terraformer_building_id 13

#   def process_event(%PlanetEvent{type: :construction_complete} = event, planet_id) do
#     %{
#       building_event: %BuildingEvent{building_id: building_id, demolish: demolish}
#     } = event

#     processed_at = DateTime.utc_now(:microsecond)

#     event_update_params = %{
#       is_processed: true,
#       completed_at: processed_at
#     }

#     Ecto.Multi.new()
#     |> Ecto.Multi.run(:upgrade_building_increment_fields, fn repo, _changes ->
#       level_increment = if demolish, do: -1, else: 1

#       from(pb in PlanetBuilding,
#         where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
#         update: [inc: [level: ^level_increment]]
#       )
#       |> repo.update_all([])

#       if not Galaxies.Buildings.production_building?(building_id) do
#         total_fields_increment =
#           if building_id == @terraformer_building_id,
#             do: Terraformer.field_increase(level_increment),
#             else: 0

#         from(p in Planet,
#           where: p.id == ^planet_id,
#           update: [inc: [used_fields: ^level_increment, total_fields: ^total_fields_increment]]
#         )
#         |> repo.update_all([])
#       end

#       {:ok, nil}
#     end)
#     |> Ecto.Multi.run(:maybe_produce_resources_on_planet, fn repo, _changes ->
#       # if the building that was upgraded was a production related building, we need to produce resources
#       # on the planet, since all production from this moment onwards will take place at a higher/lower rate.

#       if Galaxies.Buildings.production_building?(building_id) do
#         planet = repo.one!(from p in Planet, where: p.id == ^planet_id, preload: [:buildings])

#         # we produce since the last update and not since the start of the construction
#         # because many events can happen since a building starts construction
#         time_delta = DateTime.diff(processed_at, planet.updated_at, :millisecond)

#         {metal, crystal, deuterium} =
#           Production.resources_produced(planet.buildings, time_delta)

#         new_used_fields = if demolish, do: planet.used_fields - 1, else: planet.used_fields + 1

#         planet =
#           planet
#           |> change(
#             metal_units: planet.metal_units + metal,
#             crystal_units: planet.crystal_units + crystal,
#             deuterium_units: planet.deuterium_units + deuterium,
#             used_fields: new_used_fields
#           )
#           |> repo.update!()

#         {:ok, planet}
#       else
#         {:ok, nil}
#       end
#     end)
# |> Ecto.Multi.run(:planet, fn _repo, _changes ->
#   {:ok, Galaxies.Planets.get_planet_by_id(planet_id)}
# end)
# |> Ecto.Multi.run(
#   :updated_planet_and_buildings,
#   fn repo, %{planet: planet} ->
#     # we produce since the last update and not since the start of the construction
#     # because many events can happen since a building starts construction
#     time_delta = DateTime.diff(processed_at, planet.updated_at, :millisecond)

#     {metal, crystal, deuterium} =
#       Production.resources_produced(planet.buildings, time_delta)

#     planet_building =
#       planet.buildings
#       |> Enum.find(&(&1.building_id == building_id))

#     new_level =
#       if demolish do
#         planet_building.level - 1
#       else
#         planet_building.level + 1
#       end

#     # repo.update!(change(planet_building, level: new_level))

#     new_used_fields = if demolish, do: planet.used_fields - 1, else: planet.used_fields + 1

#     base_planet_changes = [
#       metal_units: planet.metal_units + metal,
#       crystal_units: planet.crystal_units + crystal,
#       deuterium_units: planet.deuterium_units + deuterium,
#       used_fields: new_used_fields
#     ]

#     terraformer_planet_changes =
#       if building_id == @terraformer_building_id and not demolish do
#         [total_fields: planet.total_fields + Terraformer.field_increase(new_level)]
#       else
#         []
#       end

#     planet =
#       planet
#       |> change(Keyword.merge(base_planet_changes, terraformer_planet_changes))
#       |> repo.update!()

#     # update local copy of planet_buildings, it may be used to update the next construction event
#     # planet_buildings =
#     #   Enum.map(planet.buildings, fn planet_building ->
#     #     if planet_building.building_id == building_id do
#     #       new_level =
#     #         if demolish do
#     #           planet_building.level - 1
#     #         else
#     #           planet_building.level + 1
#     #         end

#     #       Map.put(planet_building, :level, new_level)
#     #     else
#     #       planet_building
#     #     end
#     #   end)

#     # {:ok, Map.put(planet, :buildings, planet_buildings)}
#     {:ok, planet}
#   end
# )
# |> Ecto.Multi.update(:update_event, PlanetEvent.process_changeset(event, event_update_params))
# |> Ecto.Multi.run(:start_next_construction, fn _repo,
#                                                %{maybe_produce_resources_on_planet: _planet} ->
#   nil

# fetch all events and start the first one that meets all prerequisites to be started, if any
# next_events =
#   repo.one(
#     from e in PlanetEvent,
#       where:
#         e.planet_id == ^planet_id and e.type == ^:construction_complete and
#           e.is_processed == false and e.is_cancelled == false,
#       order_by: [asc: e.inserted_at]
#   )

# if Enum.empty?(next_events) do
#   {:ok, nil}
# else
#   planet =
#     if is_nil(planet) do
#       repo.one!(from p in Planet, where: p.id == ^planet_id, preload: [:buildings])
#     else
#       planet
#     end
# end

# if next_construction_event do
# planet =
#   if is_nil(planet) do
#     repo.one!(from p in Planet, where: p.id == ^planet_id, preload: [:buildings])
#   else
#     planet
#   end

#   %{building_event: building_event} = next_construction_event

#   level =
#     Enum.find(planet.buildings, fn planet_building ->
#       planet_building.building_id == building_event.building_id
#     end).level

#   building = Galaxies.Cached.Buildings.get_building_by_id(building_event.building_id)

#   {metal, crystal, deuterium, _energy} =
#     Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, level + 1)

#   if planet.metal_units >= metal and planet.crystal_units >= crystal and
#        planet.deuterium_units >= deuterium do
#     planet =
#       planet
#       |> change(
#         metal_units: planet.metal_units - metal,
#         crystal_units: planet.crystal_units - crystal,
#         deuterium_units: planet.deuterium_units - deuterium
#       )
#       |> repo.update!()

#     # we need to recalculate the duration of the next construction event
#     # because the previous event may impact the duration of this one.
#     # TODO replace with real formula
#     completed_at = DateTime.add(processed_at, 10, :second)

#     {:ok, _} =
#       repo.update(
#         PlanetEvent.update_changeset(next_construction_event, %{
#           started_at: processed_at,
#           completed_at: completed_at
#         })
#       )

#     {:ok, planet}
#   else
#     # insufficient resources
#     # TODO generate player notification
#     # TODO fetch next event until found or list is empty
#     {:ok, _} =
#       repo.update(
#         PlanetEvent.update_changeset(next_construction_event, %{is_cancelled: true})
#       )

#     {:ok, planet}
#   end
# else
#   {:ok, nil}
# end
#     end)
#     |> Repo.transaction()
#   end
# end
