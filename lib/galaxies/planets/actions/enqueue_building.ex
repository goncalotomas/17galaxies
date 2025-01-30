defmodule Galaxies.Planets.Actions.EnqueueBuilding do
  @behaviour Galaxies.Planets.Action

  import Ecto.Query

  require Logger
  alias Galaxies.Planet
  alias Galaxies.Accounts.Player
  alias Galaxies.Prerequisites
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.Planets.PlanetAction
  alias Galaxies.Repo

  @building_queue_max_size 5
  @terraformer_building_id 13

  def perform(%Player{} = player, %PlanetAction{type: :enqueue_building} = action) do
    now = DateTime.utc_now(:microsecond)
    %{planet_id: planet_id, data: %{building_id: building_id, demolish: demolish}} = action.data

    Ecto.Multi.new()
    |> Ecto.Multi.run(:planet, &fetch_planet(&1, &2, planet_id))
    |> Ecto.Multi.run(:data, &compile_event_data(&1, &2, building_id, demolish, player))
    |> Ecto.Multi.run(:player_techs, &maybe_fetch_player_techs/2)
    |> Ecto.Multi.run(:player_owns_planet, &check_player_owns_planet/2)
    |> Ecto.Multi.run(:enough_resources, &check_enough_resources/2)
    |> Ecto.Multi.run(:enough_planet_fields, &check_enough_planet_fields/2)
    |> Ecto.Multi.run(:prerequisites_met, &check_prerequisites/2)
    |> Ecto.Multi.run(:build_queue_not_full, &check_build_queue_not_full/2)
    |> Ecto.Multi.run(:maybe_pay_building_cost, &maybe_pay_building_cost/2)
    |> Ecto.Multi.run(
      :add_construction_complete_event,
      &add_construction_complete_event(&1, &2, now)
    )
    |> Repo.transaction()
  end

  defp fetch_planet(repo, _changes, planet_id) do
    # fetch planet with buildings and build queue
    {:ok,
     repo.one!(
       from p in Planet,
         where: p.id == ^planet_id,
         left_join: pe in assoc(p, :events),
         on:
           pe.planet_id == ^planet_id and pe.type == ^:construction_complete and
             not pe.is_processed and not pe.is_cancelled,
         join: pb in assoc(p, :buildings),
         preload: [buildings: pb, events: pe]
     )}
  end

  defp compile_event_data(_repo, %{planet: planet}, building_id, demolish, player) do
    planet_building = Enum.find(planet.buildings, fn pb -> pb.building_id == building_id end)

    target_level =
      if demolish do
        planet_building.level - 1
      else
        planet_building.level + 1
      end

    building_cost =
      building_id
      |> Galaxies.Cached.Buildings.get_building_by_id()
      |> then(&Galaxies.calc_upgrade_cost(&1.upgrade_cost_formula, target_level))

    building_prereqs = Prerequisites.get_building_prerequisites(building_id)

    {:ok,
     %{
       building_id: building_id,
       building_cost: building_cost,
       building_prereqs: building_prereqs,
       target_level: target_level,
       demolish: demolish,
       player: player
     }}
  end

  defp maybe_fetch_player_techs(repo, %{data: %{building_prereqs: prereqs, player: player}}) do
    has_research_prereqs? = Enum.any?(prereqs, fn prereq -> match?({:research, _, _}, prereq) end)

    if has_research_prereqs? do
      {:ok, repo.preload(player, [:researches]).researches}
    else
      {:ok, nil}
    end
  end

  defp check_player_owns_planet(_repo, %{planet: planet, data: %{player: player}}) do
    if planet.player_id != player.id do
      Logger.notice(
        "Player #{player.id} tried to build on a planet that does not belong to them (planet_id: #{planet.id})"
      )

      {:error, :invalid_action_build_on_other_player_planet}
    else
      {:ok, :pass}
    end
  end

  defp check_enough_resources(_repo, %{
         planet: planet,
         data: %{building_id: building_id, target_level: target_level}
       }) do
    building = Galaxies.Cached.Buildings.get_building_by_id(building_id)

    {cost_metal, cost_crystal, cost_deuterium, _cost_energy} =
      Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, target_level)

    if planet.metal_units < cost_metal or planet.crystal_units < cost_crystal or
         planet.deuterium_units < cost_deuterium do
      {:error, :not_enough_resources}
    else
      {:ok, :pass}
    end
  end

  defp check_enough_planet_fields(_repo, %{
         planet: planet,
         data: %{building_id: building_id, demolish: demolish}
       }) do
    cond do
      demolish and building_id != @terraformer_building_id ->
        {:ok, :pass}

      demolish ->
        {:error, :cannot_demolish_terraformer}

      planet.used_fields + 1 > planet.total_fields ->
        {:error, :not_enough_planet_fields}

      true ->
        {:ok, :pass}
    end
  end

  defp check_prerequisites(_repo, changes) do
    %{planet: planet, player_techs: player_techs, data: %{building_id: building_id}} = changes

    prereqs = Prerequisites.get_building_prerequisites(building_id)

    if prerequisites_met?(prereqs, player_techs, planet.buildings) do
      {:ok, :pass}
    else
      {:error, :prerequisites_not_met}
    end
  end

  defp check_build_queue_not_full(_repo, %{planet: planet}) do
    queue_length = length(planet.events)

    if queue_length >= @building_queue_max_size do
      {:error, :building_queue_full}
    else
      {:ok, :pass}
    end
  end

  defp maybe_pay_building_cost(repo, %{
         planet: planet,
         data: %{building_cost: {cost_metal, cost_crystal, cost_deuterium, _cost_energy}}
       }) do
    if Enum.empty?(planet.events) do
      # no cost is paid now because we're adding the building to the end of the queue
      {:ok, :skip}
    else
      {1, _} =
        repo.update(
          Planet.update_resources_changeset(planet, %{
            metal_units: planet.metal_units - cost_metal,
            crystal_units: planet.crystal_units - cost_crystal,
            deuterium_units: planet.deuterium_units - cost_deuterium
          })
        )

      {:ok, :done}
    end
  end

  defp add_construction_complete_event(
         repo,
         %{
           planet: planet,
           data: %{building_id: building_id, target_level: target_level, demolish: demolish}
         },
         current_time
       ) do
    construction_complete_event =
      if Enum.empty?(planet.events) do
        construction_time_seconds =
          Galaxies.Planets.building_upgrade_duration(planet.buildings, building_id, target_level)

        %PlanetEvent{
          planet_id: planet.id,
          building_event: %{
            building_id: building_id,
            demolish: demolish
          },
          type: :construction_complete,
          started_at: current_time,
          completed_at: DateTime.add(current_time, construction_time_seconds, :second)
        }
      else
        # we don't set started_at or completed_at when the queue is not empty
        %PlanetEvent{
          planet_id: planet.id,
          building_event: %{
            building_id: building_id,
            demolish: demolish
          },
          type: :construction_complete
        }
      end

    repo.insert(construction_complete_event)
  end

  # helper functions

  defp prerequisites_met?([], _player_researches, _planet_buildings), do: true

  defp prerequisites_met?([{:building, id, level} | t], player_researches, planet_buildings) do
    planet_building = Enum.find(planet_buildings, fn pb -> pb.building_id == id end)

    planet_building.level >= level and
      prerequisites_met?(t, player_researches, planet_buildings)
  end

  defp prerequisites_met?([{:research, id, level} | t], player_researches, planet_buildings) do
    player_research = Enum.find(player_researches, fn pr -> pr.research_id == id end)

    player_research.level >= level and
      prerequisites_met?(t, player_researches, planet_buildings)
  end
end
