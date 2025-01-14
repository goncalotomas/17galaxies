defmodule Galaxies.Planets.Events.ConstructionCompleteTest do
  alias Galaxies.PlanetBuilding
  alias Galaxies.Planets
  alias Galaxies.Planets.PlanetEvent
  use Galaxies.DataCase, async: true

  alias Galaxies.Planets.Events.ConstructionComplete

  import Ecto.Query

  describe "Construction Complete Event" do
    setup do
      [planet: planet_fixture()]
    end

    # TODO test that event is not processed if it is cancelled
    # TODO test that event is not processed if it is not time yet

    test "processes an event to upgrade a building", %{planet: planet} do
      building_id = 1

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: 1, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      planet_before_event = Repo.preload(planet, [:buildings])
      ConstructionComplete.process(event, planet.id)

      # assert that event was marked as processed
      event = Repo.get!(PlanetEvent, event.id)

      assert event.is_processed
      refute event.is_cancelled

      # assert that building was upgraded
      planet = Planets.get_planet_by_id(planet.id)

      building_before_event = get_planet_building(planet_before_event, building_id)
      building_after_event = get_planet_building(planet, building_id)

      assert building_after_event.level == building_before_event.level + 1

      # assert that resources were produced on planet
      assert planet.metal_units > planet_before_event.metal_units
      assert planet.crystal_units > planet_before_event.crystal_units
      assert planet.deuterium_units >= planet_before_event.deuterium_units

      # assert that the number of used fields increased
      assert planet.used_fields == planet_before_event.used_fields + 1
    end

    test "processes an event to downgrade a building", %{planet: planet} do
      building_id = 1

      # make sure building level doesn't go negative
      from(
        from pb in PlanetBuilding,
          where: pb.planet_id == ^planet.id and pb.building_id == ^building_id
      )
      |> Repo.update_all(inc: [level: 1])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: 1, duration_seconds: 30, demolish: true},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      planet_before_event = Repo.preload(planet, [:buildings])
      ConstructionComplete.process(event, planet.id)

      # assert that event was marked as processed
      event = Repo.get!(PlanetEvent, event.id)

      assert event.is_processed
      refute event.is_cancelled

      # assert that building was downgraded
      planet = Planets.get_planet_by_id(planet.id)

      building_before_event = get_planet_building(planet_before_event, building_id)
      building_after_event = get_planet_building(planet, building_id)

      assert building_after_event.level == building_before_event.level - 1

      # assert that resources were produced on planet
      assert planet.metal_units > planet_before_event.metal_units
      assert planet.crystal_units > planet_before_event.crystal_units
      assert planet.deuterium_units >= planet_before_event.deuterium_units

      # assert that the number of used fields decreased
      assert planet.used_fields == planet_before_event.used_fields - 1
    end

    test "starts next construction if there are enough resources", %{planet: planet} do
      building_id = 1

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      # create event
      next_construction_event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        )

      planet_before_event =
        planet
        |> change(
          metal_units: 1_000_000.0,
          crystal_units: 1_000_000.0,
          deuterium_units: 1_000_000.0
        )
        |> Repo.update!()
        |> Repo.preload([:buildings])

      # assert that event is processed successfully
      {:ok, _} = ConstructionComplete.process(event, planet.id)

      # assert that there were resources deducted
      planet = Planets.get_planet_by_id(planet.id)

      assert planet.metal_units < planet_before_event.metal_units
      assert planet.crystal_units < planet_before_event.crystal_units
      assert planet.deuterium_units <= planet_before_event.deuterium_units

      # refute that the next event was processed or cancelled,
      # and assert it was started
      next_event = Repo.get!(PlanetEvent, next_construction_event.id)

      refute next_event.is_cancelled
      refute next_event.is_processed
      refute is_nil(next_event.started_at)
      refute is_nil(next_event.completed_at)
    end

    test "does not start next construction if there are not enough resources", %{planet: planet} do
      building_id = 1

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      # create event
      insufficient_resources_event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        )

      planet_before_event =
        planet
        |> change(metal_units: 0.0, crystal_units: 0.0, deuterium_units: 0.0)
        |> Repo.update!()
        |> Repo.preload([:buildings])

      # assert that event is processed successfully
      {:ok, _} = ConstructionComplete.process(event, planet.id)

      # assert that there were no resources deducted,
      # only produced resources from the first event being processed
      planet = Planets.get_planet_by_id(planet.id)

      assert planet.metal_units > planet_before_event.metal_units or
               DateTime.compare(planet.updated_at, planet_before_event.updated_at) == :eq

      assert planet.crystal_units > planet_before_event.crystal_units or
               DateTime.compare(planet.updated_at, planet_before_event.updated_at) == :eq

      assert planet.deuterium_units >= planet_before_event.deuterium_units

      # assert that the next event was not processed
      cancelled_event = Repo.get!(PlanetEvent, insufficient_resources_event.id)

      assert cancelled_event.is_cancelled
    end

    test "goes through build queue if there are multiple events that can't be processed", %{
      planet: planet
    } do
      building_id = 1

      planet_before_event =
        planet
        |> change(metal_units: 0.0, crystal_units: 0.0, deuterium_units: 0.0)
        |> Repo.update!()
        |> Repo.preload([:buildings])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      events = [
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        ),
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        ),
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        )
      ]

      # assert that event is processed successfully
      {:ok, _} = ConstructionComplete.process(event, planet.id)

      # assert that there were no resources deducted,
      # only produced resources from the first event being processed
      planet = Planets.get_planet_by_id(planet.id)

      assert planet.metal_units > planet_before_event.metal_units
      assert planet.crystal_units > planet_before_event.crystal_units
      assert planet.deuterium_units >= planet_before_event.deuterium_units

      # assert that the all the events were cancelled
      for e <- events do
        event = Repo.get!(PlanetEvent, e.id)

        assert event.is_cancelled
        refute event.is_processed
      end
    end

    test "starts next valid event in build queue, even if some events got cancelled", %{
      planet: planet
    } do
      building_id = 1

      # make sure building level is high enough so that it can't be upgraded
      # with the resources on the planet
      from(
        from pb in PlanetBuilding,
          where: pb.planet_id == ^planet.id and pb.building_id == ^building_id,
          update: [set: [level: 50]]
      )
      |> Repo.update_all([])

      planet_before_event = Repo.preload(planet, [:buildings])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      [e1, e2, e3] = [
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        ),
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        ),
        # create one event that will be started successfully
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: 2, duration_seconds: 60},
          # pass in nil completed_at to enqueue after the previous event is processed
          nil
        )
      ]

      # assert that event is processed successfully
      {:ok, _} = ConstructionComplete.process(event, planet.id)

      # assert that there WERE resources deducted,
      # because one of the next events in the queue was started
      planet = Planets.get_planet_by_id(planet.id)

      assert planet.metal_units < planet_before_event.metal_units or
               planet.crystal_units < planet_before_event.crystal_units

      # assert that the all the events were cancelled
      for e <- [e1, e2] do
        event = Repo.get!(PlanetEvent, e.id)

        assert event.is_cancelled
        refute event.is_processed
      end

      started_event = Repo.get!(PlanetEvent, e3.id)
      refute started_event.is_cancelled
      refute started_event.is_processed
      refute is_nil(started_event.started_at)
      refute is_nil(started_event.completed_at)
    end

    test "energy is increased when a power plant finishes construction", %{planet: planet} do
      building_id = 4

      planet_before_event = Repo.preload(planet, [:buildings])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      {:ok, _} = ConstructionComplete.process(event, planet.id)

      planet = Planets.get_planet_by_id(planet.id)

      assert planet.total_energy > planet_before_event.total_energy
    end

    test "energy is decreased when a power plant finishes demolishing", %{planet: planet} do
      building_id = 4

      # make sure building level doesn't go negative
      upgrade_building(planet.id, building_id, 3)

      planet_before = Repo.preload(planet, [:buildings])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30, demolish: true},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      {:ok, _} = ConstructionComplete.process(event, planet.id)

      planet = Planets.get_planet_by_id(planet.id)

      assert planet.total_energy < planet_before.total_energy
    end

    test "energy is decreased when a production building finishes construction", %{planet: planet} do
      building_id = 1

      planet_before = Repo.preload(planet, [:buildings])

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      {:ok, _} = ConstructionComplete.process(event, planet.id)

      planet = Planets.get_planet_by_id(planet.id)

      assert planet.total_energy < planet_before.total_energy
    end

    test "energy is increased when a production building finishes demolishing", %{planet: planet} do
      building_id = 1

      planet_before = Repo.preload(planet, [:buildings])

      # make sure building level doesn't go negative
      upgrade_building(planet.id, building_id)

      event =
        create_event(
          :construction_complete,
          planet.id,
          %{building_id: building_id, duration_seconds: 30, demolish: true},
          DateTime.add(DateTime.utc_now(), -1, :minute)
        )

      {:ok, _} = ConstructionComplete.process(event, planet.id)

      planet = Planets.get_planet_by_id(planet.id)

      assert planet.total_energy > planet_before.total_energy
    end
  end

  defp create_event(:construction_complete, planet_id, event, completed_at) do
    %PlanetEvent{}
    |> PlanetEvent.changeset(%{
      planet_id: planet_id,
      type: :construction_complete,
      building_event: event,
      completed_at: completed_at
    })
    |> Repo.insert!()
  end

  defp get_planet_building(planet, building_id) do
    Enum.find(planet.buildings, fn planet_building ->
      planet_building.building_id == building_id
    end)
  end

  defp upgrade_building(planet_id, building_id, increments \\ 1) do
    from(
      from pb in PlanetBuilding,
        where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
        update: [inc: [level: ^increments]]
    )
    |> Repo.update_all([])
  end
end
