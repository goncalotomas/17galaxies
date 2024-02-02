defmodule Galaxies.Planets do
  @moduledoc """
  Planets context module.
  """

  import Ecto.Query

  alias Galaxies.Repo
  alias Galaxies.{Planet}
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.Planets.Events.{BuildingConstructionComplete}

  @max_events 16

  @doc """
  Processes the events on a planet
  TODO should this return the planet?
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
            limit: @max_events
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
        # TODO produce_resources(planet, until)
        {:ok, nil}
      else
        {:ok, process_events(planet, events)}
      end
    end)
    |> Ecto.Multi.run(:cleanup, fn repo, %{events: events} ->
      unless Enum.empty?(events) do
        repo.delete_all(from q in PlanetEvent, where: q.id in ^Enum.map(events, & &1.id))
      end
      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{events: events}} ->
        if length(events) == @max_events do
          process_planet_events(planet_id, until)
        else
          :ok
        end

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end

    # update production
  end

  defp process_events(planet, []), do: planet

  defp process_events(planet, [event | t]) do
    planet
    |> process_event(event)
    |> process_events(t)
  end

  def process_event(planet, %PlanetEvent{type: :building_construction_complete} = event) do
    BuildingConstructionComplete.process(planet, event)
  end

  # def process_building_construction_complete(
  #       %PlanetEvent{
  #         planet_id: planet_id,
  #         data: %{
  #           building_id: building_id,
  #           level: level,
  #         },
  #         completed_at: completed_at
  #       },
  #       until
  #     ) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.run(:planet, fn repo, _changes ->
  #     Planet
  #     |> where([p], p.id == ^planet_id)
  #     |> update([p],
  #         set: [
  #           metal_units:
  #             fragment(
  #               "? + EXTRACT(EPOCH FROM (? - ?)) * (?+?) / 3600",
  #               p.metal_units,
  #               ^completed_at,
  #               p.updated_at,
  #               p.metal_growth_rate,
  #               3600
  #             ),
  #           crystal_units:
  #             fragment(
  #               "? + EXTRACT(EPOCH FROM (? - ?)) * (?+?) / 3600",
  #               p.crystal_units,
  #               ^completed_at,
  #               p.updated_at,
  #               p.crystal_growth_rate,
  #               2800
  #             ),
  #           deuterium_units:
  #             fragment(
  #               "? + EXTRACT(EPOCH FROM (? - ?)) * ? / 3600",
  #               p.deuterium_units,
  #               ^completed_at,
  #               p.updated_at,
  #               p.deuterium_growth_rate
  #             ),
  #           updated_at: ^completed_at
  #         ]
  #       )
  #       |> select([p], p)
  #       |> repo.update_all([])
  #       |> then(fn {1, [planet]} -> planet end)
  #   end)
  #   |> Ecto.Multi.run(:planet_building, fn repo, _changes ->
  #     planet_building =
  #       repo.one!(
  #         from pb in PlanetBuilding,
  #           where: pb.building_id == ^building_id and pb.planet_id == ^planet_id,
  #           preload: [:building, :planet]
  #       )

  #     # TODO: Still need to update planet resources between planet.updated_at and
  #     # planet_building.upgrade_finished_at, something like:
  #     # Planets.update_resources(planet, planet.last_updated, planet_building.upgrade_finished_at)
  #     # Planets.update_resources(planet, planet_building.upgrade_finished_at, until)

  #     {:ok,
  #      Repo.update!(
  #        PlanetBuilding.complete_upgrade_changeset(planet_building, %{
  #          current_level: level,
  #          is_upgrading: false,
  #          upgrade_finished_at: nil
  #        })
  #      )}
  #   end)
  #   |> Ecto.Multi.run(:update_planet, fn _repo, %{planet_building: planet_building} ->
  #     planet = planet_building.planet

  #     building = planet_building.building

  #     {metal, crystal, deuterium, energy} =
  #       Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, level)

  #     cond do
  #       planet.metal_units < metal or planet.crystal_units < crystal or
  #         planet.deuterium_units < deuterium or planet.total_energy < energy ->
  #         {:error, "Not enough resources on #{planet.name} to build #{building.name}"}

  #       building.name == "Terraformer" ->
  #         extra_fields = Building.terraformer_extra_fields(level)

  #         {:ok, _} =
  #           Repo.update(
  #             Planet.upgrade_building_changeset(planet, %{
  #               used_fields: planet.used_fields + 1,
  #               total_fields: planet.total_fields + extra_fields
  #             })
  #           )

  #         {:ok, planet.used_fields + 1}

  #       planet.used_fields < planet.total_fields ->
  #         {:ok, _} =
  #           Repo.update(
  #             Planet.upgrade_building_changeset(planet, %{
  #               used_fields: planet.used_fields + 1
  #             })
  #           )

  #         {:ok, planet.used_fields + 1}

  #       true ->
  #         {:error,
  #          "The planet has no more construction space. Build or upgrade the Terraformer to increase planet fields."}
  #     end
  #   end)
  #   |> Repo.transaction()
  #   |> then(fn
  #     {:ok, result} -> {:ok, result}
  #     {:error, _step, error, _partial_changes} -> {:error, error}
  #   end)
  # end

  @doc """
  Updates the resources on a planet as a result of the resource production
  in the time interval between `from` and `to`
  """
  def update_planet_resources(_planet, _from, _to) do
    # planet_buildings = planet.planet_buildings
  end
end
