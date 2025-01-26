defmodule Galaxies.Planets.Actions.EnqueueBuilding do
  @behaviour Galaxies.Planets.Action

  import Ecto.Query

  require Logger
  alias Galaxies.Prerequisites
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.Planets.PlanetAction

  @building_queue_max_size 5

  def perform(player, %PlanetAction{type: :enqueue_building} = action) do
    %{planet_id: planet_id, data: %{building_id: building_id, demolish: demolish}} = action.data

    Ecto.Multi.new()
    |> Ecto.Multi.run(:planet, fn repo, _changes ->
      planet = repo.one!(from p in Planet, where: p.id == ^planet_id)

      if planet.player_id != player.id do
        Logger.notice(
          "Player #{player.id} tried to build on a planet that does not belong to them (planet_id: #{planet_id})"
        )

        {:error, :invalid_player_action_build_on_other_player_planet}
      else
        {:ok, planet}
      end
    end)
    |> Ecto.Multi.run(:build_queue, fn repo, _changes ->
      build_queue =
        repo.all(
          from pe in PlanetEvent,
            where:
              pe.planet_id == ^planet_id and pe.type == ^:construction_complete and
                not pe.is_processed and not pe.is_cancelled,
            order_by: [asc: pe.inserted_at]
        )

      if length(build_queue) >= @building_queue_max_size do
        {:error, :building_queue_full}
      else
        {:ok, build_queue}
      end
    end)
    |> Ecto.Multi.run(:enqueue_building, fn repo, %{build_queue: queue, planet: planet} ->
      base_event =
        PlanetEvent.changeset(%PlanetEvent{}, %{
          planet_id: planet_id,
          type: :construction_complete,
          is_processed: false,
          is_cancelled: false,
          building_event: %{
            building_id: building_id,
            demolish: demolish
          }
        })

      if Enum.empty?(queue) do
        # no buildings in progress, check for prerequisites
        planet = repo.preload(planet, [:buildings])

        

        if planet.used_fields >= planet.total_fields do
          {:error, :not_enough_planet_fields}
        else
          building = Enum.find(planet.buildings, fn b -> b.id == building_id end)

          if building do
            {:error, :building_already_exists}
          else
            {:ok, base_event}
          end
        end
      else
        # adding the building to the end of the queue
        repo.insert(base_event)
      end
    end)
    |> Repo.transaction()

    building_queue = get_building_queue(planet_id)

    case length(building_queue) do
      length when length >= @building_queue_max_size ->
        {:error, :building_queue_full}

      0 ->
        # no other buildings in progress, subtract building cost
        planet_buildings =
          Repo.all(
            from pb in PlanetBuilding,
              where: pb.planet_id == ^planet_id,
              select: pb,
              preload: [:building]
          )

        planet_building = Enum.find(planet_buildings, fn pb -> pb.building_id == building_id end)

        {cost_metal, cost_crystal, cost_deuterium, _energy} =
          Galaxies.calc_upgrade_cost(planet_building.building.upgrade_cost_formula, level)

        %{
          metal_units: planet_metal,
          crystal_units: planet_crystal,
          deuterium_units: planet_deuterium
        } =
          _planet =
          Repo.one!(
            from p in Planet,
              where: p.id == ^planet_id
          )

        if planet_metal >= cost_metal and planet_crystal >= cost_crystal and
             planet_deuterium >= cost_deuterium do
          add_resources(planet_id, -cost_metal, -cost_crystal, -cost_deuterium)

          # TODO: replace with a real formula
          construction_duration_seconds = :math.pow(2, level) |> trunc()

          event_id = Ecto.UUID.generate()
          now = DateTime.utc_now(:second)

          Repo.insert!(%PlanetEvent{
            planet_id: planet_id,
            completed_at: DateTime.add(now, construction_duration_seconds),
            type: :building_construction,
            building_event: %BuildingEvent{
              id: event_id,
              list_order: 1,
              planet_id: planet_id,
              building_id: building_id,
              level: level,
              demolish: false,
              started_at: now,
              completed_at: DateTime.add(now, construction_duration_seconds)
            }
          })

          :ok
        else
          {:error, :not_enough_resources}
        end

      _ ->
        # adding at the end of the queue which means level could be wrong
        # (e.g. trying to update metal mine twice from level 10 will yield 2 events with level = 11)
        # so we need to set level to a proper value (highest in queue + 1)
        {level, list_order} =
          Enum.reduce(building_queue, {level, 1}, fn %EnqueuedBuilding{
                                                       list_order: lo,
                                                       building_id: b_id,
                                                       level: lvl
                                                     },
                                                     {acc_level, acc_order} ->
            level =
              if b_id == building_id and lvl >= acc_level do
                lvl + 1
              else
                acc_level
              end

            order =
              if lo >= acc_order do
                lo + 1
              else
                acc_order
              end

            {level, order}
          end)

        # TODO: replace with a real formula
        construction_duration_seconds = :math.pow(2, level) |> trunc()

        now = DateTime.utc_now(:second)

        # no PlanetEvent is inserted because we are inserting at the end of the queue,
        # so an event already exists to fetch from the head of the queue.
        Repo.insert!(%EnqueuedBuilding{
          planet_id: planet_id,
          list_order: list_order,
          building_id: building_id,
          level: level,
          demolish: false,
          started_at: now,
          completed_at: DateTime.add(now, construction_duration_seconds, :second)
        })

        :ok
    end
  end
end
