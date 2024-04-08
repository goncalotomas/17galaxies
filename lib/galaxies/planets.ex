defmodule Galaxies.Planets do
  @moduledoc """
  Planets context module.
  """

  import Ecto.Query

  require Logger
  alias Galaxies.PlayerResearch
  alias Galaxies.Planets.EnqueuedBuilding
  alias Galaxies.Planets.Production
  alias Galaxies.PlanetBuilding
  alias Galaxies.Prerequisites
  alias Galaxies.Repo
  alias Galaxies.{Planet}
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.Planets.Events.{BuildingConstructionComplete}

  @max_planet_events_to_read 16
  @building_queue_max_size 15

  @doc """
  Enqueues the construction of a building on a planet.
  Checks if the user has the prerequisites to enqueue the building.
  If the building queue for that planet is empty, resources are subtracted from the planet.
  Otherwise just inserts a new planet event
  """
  def enqueue_building(planet_id, building_id, level) do
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
          construction_duration_seconds = level + 1

          event_id = Ecto.UUID.generate()
          now = DateTime.utc_now(:second)

          Repo.insert!(%EnqueuedBuilding{
            id: event_id,
            list_order: 1,
            planet_id: planet_id,
            building_id: building_id,
            level: level,
            demolish: false,
            started_at: now,
            completed_at: DateTime.add(now, construction_duration_seconds)
          })

          Repo.insert!(%PlanetEvent{
            planet_id: planet_id,
            completed_at: DateTime.add(now, construction_duration_seconds),
            type: :building_construction,
            event_id: event_id,
            data: %{}
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
        construction_duration_seconds = level + 1

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

  @doc """
  Fetches the building queue for a specific planet.
  """
  def get_building_queue(planet_id) do
    Repo.all(
      from eb in EnqueuedBuilding,
        where: eb.planet_id == ^planet_id,
        order_by: eb.list_order,
        select: eb,
        preload: :building
    )
  end

  @doc """
  Adds a certain amount of resources to a planet.
  The resource amounts can be negative and no checks are made to see if the
  resulting amount on the planet is valid. Callers of this function should first
  verify if the resource amounts on the planet are sufficient when calling this
  function with negative amounts.
  This function updates the updated_at timestamp on the planet.
  """
  def add_resources(planet_id, metal, crystal, deuterium) do
    from(p in Planet,
      where: p.id == ^planet_id,
      update: [
        inc: [metal_units: ^metal, crystal_units: ^crystal, deuterium_units: ^deuterium],
        set: [updated_at: ^DateTime.utc_now()]
      ]
    )
    |> Repo.update_all([])

    :ok
  end

  @doc """
  Processes the event queue of a planet up until a specified timestamp.
  If no events are found, it updates the resource count on the planet.
  Each event of type `:building_construction` processed from the queue will
  result in the following actions:
  - If the inserted_at timestamp has already passed:
    - The Planet will be updated to reflect updated resource counts
  - If the completed_at timestamp has already passed:
    - The PlanetBuilding will be updated to reflect the new building level
    - The Planet will be updated with a new used fields count
    - The next event will be fetched and the same logic applied to it
  """
  def process_planet_events(planet_id, until \\ DateTime.utc_now()) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:events, fn repo, _changes ->
      events =
        repo.all(
          from q in PlanetEvent,
            where: q.planet_id == ^planet_id,
            where: q.completed_at < ^until,
            # TODO address some of the concurrent events with integer priority column
            order_by: [asc: q.completed_at],
            limit: @max_planet_events_to_read
        )

      {:ok, events}
    end)
    |> Ecto.Multi.run(:planet, fn repo, _changes ->
      planet =
        repo.one(
          from p in Planet,
            where: p.id == ^planet_id,
            preload: [buildings: :building, units: :unit]
        )

      {:ok, planet}
    end)
    |> Ecto.Multi.run(:process_events, fn _repo, %{planet: planet, events: events} ->
      if Enum.empty?(events) do
        now_before_producing = DateTime.utc_now(:millisecond)
        produce_resources(planet, until)

        ms_elapsed =
          DateTime.diff(DateTime.utc_now(:millisecond), now_before_producing, :millisecond)

        Logger.debug("produced resources in #{ms_elapsed}ms for planet #{planet.id}")
        {:ok, nil}
      else
        now_before_processing = DateTime.utc_now(:millisecond)
        {event_count, planet} = process_events(planet, events, until)

        ms_elapsed =
          DateTime.diff(DateTime.utc_now(:millisecond), now_before_processing, :millisecond)

        Logger.info("processed #{event_count} events in #{ms_elapsed}ms for planet #{planet.id}")
        {:ok, planet}
      end
    end)
    # |> Ecto.Multi.run(:cleanup, fn repo, %{events: events} ->
    #   unless Enum.empty?(events) do
    #     repo.delete_all(from q in PlanetEvent, where: q.id in ^Enum.map(events, & &1.id))
    #   end

    #   {:ok, nil}
    # end)
    |> Repo.transaction()
    |> case do
      {:ok, %{events: events}} ->
        if length(events) == @max_planet_events_to_read do
          process_planet_events(planet_id, until)
        else
          :ok
        end

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp process_events(planet, event_list, until, events_processed \\ 0)

  defp process_events(planet, [], _until, events_processed) do
    {events_processed, planet}
  end

  defp process_events(planet, [event | t], until, events_processed) do
    {:ok, extra_events} = process_event(planet, event)

    extra_events =
      Enum.filter(extra_events, fn e -> not DateTime.after?(e.completed_at, until) end)

    merged_events = merge_events(t, extra_events)

    if length(merged_events) != length(t) do
      Logger.debug(
        "Kept #{length(merged_events) - length(t)} extra event(s) while processing events for planet #{planet.id}"
      )
    end

    process_events(planet, merge_events(t, extra_events), until, events_processed + 1)
  end

  defp merge_events(l1, []), do: l1

  defp merge_events(l1, l2) do
    Enum.sort(l1 ++ l2, fn e1, e2 -> DateTime.before?(e1.completed_at, e2.completed_at) end)
  end

  @doc """
  Updates the resource count to reflect planet production since the last time the planet was updated.
  """
  def produce_resources(planet, from \\ nil, until) do
    ms_elapsed = DateTime.diff(until, from || planet.updated_at, :millisecond)
    {metal, crystal, deuterium} = Production.resources_produced(planet.buildings, ms_elapsed)
    add_resources(planet.id, metal, crystal, deuterium)
  end

  def process_event(planet, %PlanetEvent{type: :building_construction} = event) do
    BuildingConstructionComplete.process(planet, event)
  end

  @doc """
  Updates the resources on a planet as a result of the resource production
  in the time interval between `from` and `to`
  """
  def get_planet_buildings(planet_id) do
    Repo.all(
      from pb in PlanetBuilding,
        where: pb.planet_id == ^planet_id,
        select: pb,
        preload: [:building]
    )
  end

  def get_planet_by_id(planet_id) do
    Repo.one!(
      from p in Planet,
        where: p.id == ^planet_id
    )
  end

  @doc """
  Checks whether a building can be built on a specific location
  taking only into consideration the prerequisites for that building
  (i.e. does not do any checks for available fields)
  """
  def can_build_building?(planet, building_id) do
    prereqs = Prerequisites.get_building_prerequisites(building_id)
    # currently only buildings have the possibility of not having prerequisites.
    if prereqs == [] do
      true
    else
      player_researches =
        Repo.all(from pr in PlayerResearch, where: pr.player_id == ^planet.player_id)

      planet_buildings = Repo.all(from pb in PlanetBuilding, where: pb.planet_id == ^planet.id)
      check_prerequisites(prereqs, player_researches, planet_buildings)
    end
  end

  @doc """
  Checks whether a research can be built on a specific location
  taking only into consideration the prerequisites for that research
  """
  def can_build_research?(planet, research_id) do
    prereqs = Prerequisites.get_research_prerequisites(research_id)
    player_researches =
      Repo.all(from pr in PlayerResearch, where: pr.player_id == ^planet.player_id)

    planet_buildings = Repo.all(from pb in PlanetBuilding, where: pb.planet_id == ^planet.id)
    check_prerequisites(prereqs, player_researches, planet_buildings)
  end

  @doc """
  Checks whether a unit can be built on a specific location
  taking only into consideration the prerequisites for that unit
  """
  def can_build_unit?(planet, unit_id) do
    prereqs = Prerequisites.get_unit_prerequisites(unit_id)
    player_researches =
      Repo.all(from pr in PlayerResearch, where: pr.player_id == ^planet.player_id)

    planet_buildings = Repo.all(from pb in PlanetBuilding, where: pb.planet_id == ^planet.id)
    check_prerequisites(prereqs, player_researches, planet_buildings)
  end

  defp check_prerequisites([], _player_researches, _planet_buildings), do: true

  defp check_prerequisites([{:building, id, level} | t], player_researches, planet_buildings) do
    planet_building = Enum.find(planet_buildings, fn pb -> pb.building_id == id end)

    planet_building.current_level >= level and
      check_prerequisites(t, player_researches, planet_buildings)
  end

  defp check_prerequisites([{:research, id, level} | t], player_researches, planet_buildings) do
    player_research = Enum.find(player_researches, fn pr -> pr.research_id == id end)

    player_research.current_level >= level and
      check_prerequisites(t, player_researches, planet_buildings)
  end
end
