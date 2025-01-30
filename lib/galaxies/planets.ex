defmodule Galaxies.Planets do
  @moduledoc """
  Planets context module.
  """

  import Ecto.Query

  require Logger
  alias Galaxies.PlayerResearch
  alias Galaxies.PlanetBuilding
  alias Galaxies.Prerequisites
  alias Galaxies.Repo
  alias Galaxies.{Planet}
  alias Galaxies.Planets.PlanetEvent

  # @max_planet_events_to_read 16
  @building_queue_max_size 5
  @research_queue_max_size 5

  # TODO move hardcoded building IDs to some config
  @universe_speed 100
  @base_construction_speed_factor 2500
  @robot_factory_building_id 9
  @nanite_factory_building_id 10

  @doc """
  Enqueues the construction of a building on a planet.
  Checks if the user has the prerequisites to enqueue the building.
  If the building queue for that planet is empty, resources are subtracted from the planet.
  Otherwise just inserts a new planet event
  """
  def enqueue_building(_planet_id, _building_id, _level) do
    # building_queue = get_building_queue(planet_id)

    # case length(building_queue) do
    #   length when length >= @building_queue_max_size ->
    #     {:error, :building_queue_full}

    #   0 ->
    #     # no other buildings in progress, subtract building cost
    #     planet_buildings =
    #       Repo.all(
    #         from pb in PlanetBuilding,
    #           where: pb.planet_id == ^planet_id,
    #           select: pb,
    #           preload: [:building]
    #       )

    #     planet_building = Enum.find(planet_buildings, fn pb -> pb.building_id == building_id end)

    #     {cost_metal, cost_crystal, cost_deuterium, _energy} =
    #       Galaxies.calc_upgrade_cost(planet_building.building.upgrade_cost_formula, level)

    #     %{
    #       metal_units: planet_metal,
    #       crystal_units: planet_crystal,
    #       deuterium_units: planet_deuterium
    #     } =
    #       _planet =
    #       Repo.one!(
    #         from p in Planet,
    #           where: p.id == ^planet_id
    #       )

    #     if planet_metal >= cost_metal and planet_crystal >= cost_crystal and
    #          planet_deuterium >= cost_deuterium do
    #       add_resources(planet_id, -cost_metal, -cost_crystal, -cost_deuterium)

    #       # TODO: replace with a real formula
    #       construction_duration_seconds = :math.pow(2, level) |> trunc()

    #       event_id = Ecto.UUID.generate()
    #       now = DateTime.utc_now(:second)

    #       Repo.insert!(%PlanetEvent{
    #         planet_id: planet_id,
    #         completed_at: DateTime.add(now, construction_duration_seconds),
    #         type: :building_construction,
    #         building_event: %BuildingEvent{
    #           id: event_id,
    #           list_order: 1,
    #           planet_id: planet_id,
    #           building_id: building_id,
    #           level: level,
    #           demolish: false,
    #           started_at: now,
    #           completed_at: DateTime.add(now, construction_duration_seconds)
    #         }
    #       })

    #       :ok
    #     else
    #       {:error, :not_enough_resources}
    #     end

    #   _ ->
    #     # adding at the end of the queue which means level could be wrong
    #     # (e.g. trying to update metal mine twice from level 10 will yield 2 events with level = 11)
    #     # so we need to set level to a proper value (highest in queue + 1)
    #     {level, list_order} =
    #       Enum.reduce(building_queue, {level, 1}, fn %EnqueuedBuilding{
    #                                                    list_order: lo,
    #                                                    building_id: b_id,
    #                                                    level: lvl
    #                                                  },
    #                                                  {acc_level, acc_order} ->
    #         level =
    #           if b_id == building_id and lvl >= acc_level do
    #             lvl + 1
    #           else
    #             acc_level
    #           end

    #         order =
    #           if lo >= acc_order do
    #             lo + 1
    #           else
    #             acc_order
    #           end

    #         {level, order}
    #       end)

    #     # TODO: replace with a real formula
    #     construction_duration_seconds = :math.pow(2, level) |> trunc()

    #     now = DateTime.utc_now(:second)

    #     # no PlanetEvent is inserted because we are inserting at the end of the queue,
    #     # so an event already exists to fetch from the head of the queue.
    #     Repo.insert!(%EnqueuedBuilding{
    #       planet_id: planet_id,
    #       list_order: list_order,
    #       building_id: building_id,
    #       level: level,
    #       demolish: false,
    #       started_at: now,
    #       completed_at: DateTime.add(now, construction_duration_seconds, :second)
    #     })

    #     :ok
    # end
  end

  @doc """
  Fetches the building queue for a specific planet.
  """
  def get_building_queue(planet_id) do
    Repo.all(
      from pe in PlanetEvent,
        where:
          pe.planet_id == ^planet_id and pe.type == ^:construction_complete and
            not pe.is_cancelled and not pe.is_processed,
        order_by: pe.inserted_at,
        limit: @building_queue_max_size
    )
  end

  @doc """
  Returns the duration of a building upgrade in seconds for a given planet.
  The duration depends on the cost of the upgrade, but also on the level of the planet's robot and nanite factories.
  """
  def building_upgrade_duration(planet_buildings, building_id, level) do
    building = Galaxies.Cached.Buildings.get_building_by_id(building_id)

    {cost_metal, cost_crystal, _cost_deuterium, _cost_energy} =
      Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, level)

    robot_factory =
      Enum.find(planet_buildings, fn pb -> pb.building_id == @robot_factory_building_id end)

    nanite_factory =
      Enum.find(planet_buildings, fn pb -> pb.building_id == @nanite_factory_building_id end)

    num = cost_metal + cost_crystal

    low_level_factor = if level < 5, do: 7, else: 1

    den =
      @base_construction_speed_factor * (1 + robot_factory.level) *
        :math.pow(2, nanite_factory.level) * @universe_speed * low_level_factor

    trunc(:math.ceil(num / den))
  end

  @doc """
  Fetches the research queue for a specific planet.
  """
  def get_research_queue(planet_id) do
    Repo.all(
      from pe in PlanetEvent,
        where:
          pe.planet_id == ^planet_id and pe.type == ^:research_complete and
            not pe.is_cancelled and not pe.is_processed,
        order_by: pe.inserted_at,
        limit: @research_queue_max_size
    )
  end

  @doc """
  Fetches the research queue for a specific planet.
  """
  def get_unit_build_queue(planet_id) do
    Repo.all(
      from pe in PlanetEvent,
        where:
          pe.planet_id == ^planet_id and pe.type == ^:unit_production_complete and
            not pe.is_cancelled and not pe.is_processed,
        order_by: pe.inserted_at,
        limit: @research_queue_max_size
    )
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
  def process_planet_events(_planet_id, _until \\ DateTime.utc_now()) do
    # Ecto.Multi.new()
    # |> Ecto.Multi.run(:events, fn repo, _changes ->
    #   events =
    #     repo.all(
    #       from q in PlanetEvent,
    #         where: q.planet_id == ^planet_id,
    #         where: q.completed_at < ^until,
    #         # TODO address some of the concurrent events with integer priority column
    #         order_by: [asc: q.completed_at],
    #         limit: @max_planet_events_to_read
    #     )

    #   {:ok, events}
    # end)
    # |> Ecto.Multi.run(:planet, fn repo, _changes ->
    #   planet =
    #     repo.one(
    #       from p in Planet,
    #         where: p.id == ^planet_id,
    #         preload: [buildings: :building, units: :unit]
    #     )

    #   {:ok, planet}
    # end)
    # |> Ecto.Multi.run(:process_events, fn _repo, %{planet: planet, events: events} ->
    #   if Enum.empty?(events) do
    #     now_before_producing = DateTime.utc_now(:millisecond)
    #     produce_resources(planet, until)

    #     ms_elapsed =
    #       DateTime.diff(DateTime.utc_now(:millisecond), now_before_producing, :millisecond)

    #     Logger.debug("produced resources in #{ms_elapsed}ms for planet #{planet.id}")
    #     {:ok, nil}
    #   else
    #     started_at = DateTime.utc_now(:microsecond)
    #     {event_count, planet} = process_events(planet, events, until)
    #     finished_at = DateTime.utc_now(:microsecond)

    #     log_stats(planet.id, event_count, finished_at, started_at)

    #     {:ok, planet}
    #   end
    # end)
    # # |> Ecto.Multi.run(:cleanup, fn repo, %{events: events} ->
    # #   unless Enum.empty?(events) do
    # #     repo.delete_all(from q in PlanetEvent, where: q.id in ^Enum.map(events, & &1.id))
    # #   end

    # #   {:ok, nil}
    # # end)
    # |> Repo.transaction()
    # |> case do
    #   {:ok, %{events: events}} ->
    #     if length(events) == @max_planet_events_to_read do
    #       process_planet_events(planet_id, until)
    #     else
    #       :ok
    #     end

    #   {:error, _failed_operation, failed_value, _changes_so_far} ->
    #     {:error, failed_value}
    # end
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
        where: p.id == ^planet_id,
        preload: [:buildings]
    )
  end

  @doc """
  Checks whether a building can be built on a specific location
  taking only into consideration the prerequisites for that building
  (i.e. does not do any checks for available fields)
  """
  def can_build_building?(planet, building_id) do
    prereqs = Prerequisites.get_building_prerequisites(building_id)

    if prereqs == [] do
      true
    else
      player_researches =
        Repo.all(from pr in PlayerResearch, where: pr.player_id == ^planet.player_id)

      planet_buildings =
        if Ecto.assoc_loaded?(planet.buildings) do
          planet.buildings
        else
          Repo.all(from pb in PlanetBuilding, where: pb.planet_id == ^planet.id)
        end

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

    planet_building.level >= level and
      check_prerequisites(t, player_researches, planet_buildings)
  end

  defp check_prerequisites([{:research, id, level} | t], player_researches, planet_buildings) do
    player_research = Enum.find(player_researches, fn pr -> pr.research_id == id end)

    player_research.level >= level and
      check_prerequisites(t, player_researches, planet_buildings)
  end

  # defp log_stats(planet_id, event_count, finished_at, started_at) do
  #   diff = DateTime.diff(finished_at, started_at, :microsecond)

  #   log_msg =
  #     cond do
  #       event_count == 0 ->
  #         nil

  #       diff < 1000 ->
  #         "processed #{event_count} events for planet##{planet_id} in #{diff}μs"

  #       diff < 100_000 ->
  #         "processed #{event_count} events for planet##{planet_id} in #{div(diff, 1000)}ms"

  #       true ->
  #         "processed #{event_count} events for planet##{planet_id} in #{Float.ceil(diff / 1_000_000, 3)}s"
  #     end

  #   if log_msg do
  #     Logger.debug(log_msg)
  #   end

  #   :ok
  # end
end
