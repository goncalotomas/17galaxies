defmodule Galaxies.Planets.Events.BuildingConstructionComplete do
  @moduledoc """
  Event processor module for when a building construction is complete.
  When this type of event happens it generates the following changes:
  - The PlanetBuilding is updated to reflect the new level and completion time
  - The next event of the same type is updated to reflect the start and end times
    after the completion time of the current building and an attempt is made to
    start the construction (subtract resources, check prerequisites, etc).
  """
  @behaviour Galaxies.Planets.GenEvent

  import Ecto.Query

  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.Planets
  alias Galaxies.Planets.EnqueuedBuilding
  alias Galaxies.Repo
  alias Galaxies.{Planet, PlanetBuilding}

  @doc """
  Finishes the current construction by upgrading the appropriate PlanetBuilding.
  Deletes the enqueued building as well as the PlanetEvent that triggered the execution of this function.
  Attempts to start the next construction in the queue.
  """
  def process(planet, _planet_event) do
    # TODO: We need to check the event_id in the planet event and fetch that.
    # the reason is that we could be processing an event that was cancelled.
    # if the event is cancelled we will likely want to skip updating the planetbuilding
    # but we'll also still need to call maybe_start_next_construction(?)
    {:ok,
     %EnqueuedBuilding{
       building_id: building_id,
       level: level,
       demolish: demolish,
       completed_at: completed_at
     } = enqueued} = get_building_in_progress(planet.id)

    :ok = update_planet_building(planet.id, building_id, level, completed_at)

    :ok = Planets.produce_resources(planet, enqueued.completed_at)
    :ok = update_planet_fields(planet.id, building_id, level, demolish)
    :ok = delete_completed_building_event(planet.id, enqueued)
    # TODO maybe_start_next_construction must loop through buildings not in progress and see
    # if at least one of them can be started. One or more of them may not be started (e.g. lack of resources)
    # fix: allow the function to fetch the building queue for the planet and loop through it
    maybe_start_next_construction(planet.id, get_building_in_progress(planet.id), completed_at)
  end

  defp get_building_in_progress(planet_id) do
    query =
      from q in EnqueuedBuilding,
        where: q.planet_id == ^planet_id,
        order_by: [asc: q.list_order],
        limit: 1

    case Repo.one(query) do
      nil -> {:error, :empty_build_queue}
      enqueued_building -> {:ok, enqueued_building}
    end
  end

  defp update_planet_building(planet_id, building_id, level, completed_at) do
    query =
      from(pb in PlanetBuilding,
        where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
        update: [
          set: [
            current_level: ^level,
            updated_at: ^completed_at
          ]
        ]
      )

    {1, _} = Repo.update_all(query, [])
    :ok
  end

  defp update_planet_fields(planet_id, building_id, level, demolish) do
    used_fields_inc = Galaxies.Buildings.used_fields_increase(building_id, level, demolish)
    total_fields_inc = Galaxies.Buildings.total_fields_increase(building_id, level, demolish)

    from(p in Planet,
      where: p.id == ^planet_id,
      update: [
        inc: [
          used_fields: ^used_fields_inc,
          total_fields: ^total_fields_inc
        ]
      ]
    )
    |> Repo.update_all([])

    :ok
  end

  defp delete_completed_building_event(planet_id, enqueued) do
    id = enqueued.id
    Repo.delete!(enqueued)

    Repo.delete_all(
      from pe in PlanetEvent,
        where: pe.planet_id == ^planet_id and pe.event_id == ^id
    )

    :ok
  end

  defp maybe_start_next_construction(_planet_id, {:error, :empty_build_queue}, _), do: {:ok, []}

  defp maybe_start_next_construction(
         planet_id,
         {:ok,
          %EnqueuedBuilding{
            id: id,
            building_id: building_id,
            level: level
          } = enqueued_building},
         started_at
       ) do
    planet_buildings = Planets.get_planet_buildings(planet_id)
    planet_building = Enum.find(planet_buildings, fn pb -> pb.building_id == building_id end)

    {cost_metal, cost_crystal, cost_deuterium, _energy} =
      Galaxies.calc_upgrade_cost(planet_building.building.upgrade_cost_formula, level)

    %{
      metal_units: planet_metal,
      crystal_units: planet_crystal,
      deuterium_units: planet_deuterium
    } = Planets.get_planet_by_id(planet_id)

    if planet_metal >= cost_metal and planet_crystal >= cost_crystal and
         planet_deuterium >= cost_deuterium do
      Planets.add_resources(planet_id, -cost_metal, -cost_crystal, -cost_deuterium)

      # update enqueued_building to reflect new start and end times
      # TODO: replace with a real formula
      construction_duration_seconds = 2 * level
      completed_at = DateTime.add(started_at, construction_duration_seconds, :second)

      Repo.update!(
        EnqueuedBuilding.advance_building_queue_changeset(enqueued_building, %{
          started_at: started_at,
          completed_at: completed_at
        })
      )

      event =
        Repo.insert!(%PlanetEvent{
          planet_id: planet_id,
          completed_at: completed_at,
          type: :building_construction,
          event_id: id
        })

      {:ok, [event]}
    else
      {:ok, []}
    end
  end
end
