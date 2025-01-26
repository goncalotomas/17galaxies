defmodule Galaxies.PlanetsTest do
  alias Galaxies.Planets.PlanetEvent
  alias Galaxies.PlayerResearch
  alias Galaxies.PlanetBuilding
  use Galaxies.DataCase, async: true

  alias Galaxies.{Building, Planets, Research, Unit}

  @mine_metal_building_id 1

  setup do
    {:ok, planet: planet_fixture()}
  end

  describe "get_building_queue/1" do
    test "returns events only for the planet_id specified", %{planet: planet} do
      other_planet = planet_fixture()

      # create events for both planets
      ten_mins_from_now = DateTime.utc_now() |> DateTime.add(10, :minute)
      e1 = create_event(:construction_complete, planet.id, %{building_id: 1}, ten_mins_from_now)
      e2 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e3 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e4 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e5 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      create_event(:construction_complete, other_planet.id, %{building_id: 2}, ten_mins_from_now)
      create_event(:construction_complete, other_planet.id, %{building_id: 2}, nil)
      create_event(:construction_complete, other_planet.id, %{building_id: 2}, nil)
      create_event(:construction_complete, other_planet.id, %{building_id: 2}, nil)
      create_event(:construction_complete, other_planet.id, %{building_id: 2}, nil)

      assert [e1, e2, e3, e4, e5] == Planets.get_building_queue(planet.id)
    end

    test "does not return cancelled events", %{planet: planet} do
      ten_mins_from_now = DateTime.utc_now() |> DateTime.add(10, :minute)
      e1 = create_event(:construction_complete, planet.id, %{building_id: 1}, ten_mins_from_now)
      e2 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e3 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e4 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)
      e5 = create_event(:construction_complete, planet.id, %{building_id: 1}, nil)

      for event <- [e2, e4] do
        Repo.update!(PlanetEvent.update_changeset(event, %{is_cancelled: true}))
      end

      assert [e1, e3, e5] == Planets.get_building_queue(planet.id)
    end
  end

  describe "can_build_building?/2" do
    test "returns true when buildings have no prerequisites", %{planet: planet} do
      assert Planets.can_build_building?(planet, @mine_metal_building_id)
    end

    test "returns false when there are multiple missing prerequisites", %{planet: planet} do
      # nanite factory requires level 10 computer tech, level 10 robot factory
      robot_factory = Repo.one!(from b in Building, where: b.name == "Robot Factory")
      nanite_factory = Repo.one!(from b in Building, where: b.name == "Nanite Factory")
      computer_tech = Repo.one!(from r in Research, where: r.name == "Computer Technology")

      # no requirements are met
      set_planet_building_level(planet.id, robot_factory.id, 9)
      set_player_research_level(planet.player_id, computer_tech.id, 9)

      refute Planets.can_build_building?(planet, nanite_factory.id)
    end

    test "returns false when there are missing prerequisites (research)", %{planet: planet} do
      # nanite factory requires level 10 computer tech, level 10 robot factory
      robot_factory = Repo.one!(from b in Building, where: b.name == "Robot Factory")
      nanite_factory = Repo.one!(from b in Building, where: b.name == "Nanite Factory")
      computer_tech = Repo.one!(from r in Research, where: r.name == "Computer Technology")

      set_planet_building_level(planet.id, robot_factory.id, 10)

      # if player does not have level 10 (or higher) computer tech, calling the function will return false
      players_computer_tech =
        Repo.one!(from pr in PlayerResearch, where: pr.research_id == ^computer_tech.id)

      assert players_computer_tech.level < 10
      refute Planets.can_build_building?(planet, nanite_factory.id)
    end

    test "returns false when there are missing prerequisites (buildings)", %{planet: planet} do
      # terraformer requires level 1 nanite factory, level 12 energy tech
      nanite_factory = Repo.one!(from b in Building, where: b.name == "Nanite Factory")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")

      # set energy tech to above requirements
      set_player_research_level(planet.player_id, energy_tech.id, 14)

      # if planet does not have level 1 (or higher) nanite factory, calling the function will return false
      planets_nanite_factory =
        Repo.one!(from pb in PlanetBuilding, where: pb.building_id == ^nanite_factory.id)

      assert planets_nanite_factory.level == 0
      refute Planets.can_build_building?(planet, nanite_factory.id)
    end

    test "returns true when research prerequisites are exactly met (case 1)", %{planet: planet} do
      # missile silo requires level 1 Shipyard
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")
      missile_silo = Repo.one!(from b in Building, where: b.name == "Missile Silo")

      refute Planets.can_build_building?(planet, missile_silo.id)

      # set shipyard to level 1 (exact requirement)
      set_planet_building_level(planet.id, shipyard.id, 1)

      assert Planets.can_build_building?(planet, missile_silo.id)
    end

    test "returns true when research prerequisites are exactly met (case 2)", %{planet: planet} do
      # fusion reactor requires level 5 deuterium synthesizer and level 3 energy tech
      fusion_reactor = Repo.one!(from b in Building, where: b.name == "Fusion Reactor")
      deuterium_synth = Repo.one!(from b in Building, where: b.name == "Deuterium Synthesizer")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")

      refute Planets.can_build_building?(planet, fusion_reactor.id)

      # set exact requirements
      set_planet_building_level(planet.id, deuterium_synth.id, 5)
      set_player_research_level(planet.player_id, energy_tech.id, 3)

      assert Planets.can_build_building?(planet, fusion_reactor.id)
    end

    test "returns true when research prerequisites are more than met (case 1)", %{planet: planet} do
      # shipyard requires level 2 robot factory
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")
      robot_factory = Repo.one!(from b in Building, where: b.name == "Robot Factory")

      refute Planets.can_build_building?(planet, shipyard.id)

      # set robot factory above prerequisite expectation
      set_planet_building_level(planet.id, robot_factory.id, 15)

      assert Planets.can_build_building?(planet, shipyard.id)
    end

    test "returns true when research prerequisites are more than met (case 2)", %{planet: planet} do
      # nanite factory requires level 10 robot factory, level 10 computer tech
      nanite_factory = Repo.one!(from b in Building, where: b.name == "Nanite Factory")
      robot_factory = Repo.one!(from b in Building, where: b.name == "Robot Factory")
      computer_tech = Repo.one!(from r in Research, where: r.name == "Computer Technology")

      refute Planets.can_build_building?(planet, nanite_factory.id)

      # set robot factory above prerequisite expectation
      set_planet_building_level(planet.id, robot_factory.id, 99)
      set_player_research_level(planet.player_id, computer_tech.id, 30)

      assert Planets.can_build_building?(planet, nanite_factory.id)
    end
  end

  describe "can_build_research?/2" do
    test "returns false when there are multiple missing prerequisites", %{planet: planet} do
      # laser tech requires level 1 research lab, level 2 energy tech
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      laser_tech = Repo.one!(from r in Research, where: r.name == "Laser Technology")

      # no requirements are met
      set_planet_building_level(planet.id, research_lab.id, 0)
      set_player_research_level(planet.player_id, energy_tech.id, 1)

      refute Planets.can_build_research?(planet, laser_tech.id)
    end

    test "returns false when there are missing prerequisites (research)", %{planet: planet} do
      # laser tech requires level 1 research lab, level 2 energy tech
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      laser_tech = Repo.one!(from r in Research, where: r.name == "Laser Technology")

      # meet building requirements but not research requirements
      set_planet_building_level(planet.id, research_lab.id, 3)
      set_player_research_level(planet.player_id, energy_tech.id, 1)

      refute Planets.can_build_research?(planet, laser_tech.id)
    end

    test "returns false when there are missing prerequisites (buildings)", %{planet: planet} do
      # hyperspace tech requires level 7 research lab, level 5 energy tech, level 5 shield tech
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      shield_tech = Repo.one!(from r in Research, where: r.name == "Shields Technology")
      hyperspace_tech = Repo.one!(from r in Research, where: r.name == "Hyperspace Technology")

      # meet research requirements but not building requirements
      set_player_research_level(planet.player_id, energy_tech.id, 10)
      set_player_research_level(planet.player_id, shield_tech.id, 10)
      set_planet_building_level(planet.id, research_lab.id, 6)

      refute Planets.can_build_research?(planet, hyperspace_tech.id)
    end

    test "returns true when research prerequisites are exactly met (case 1)", %{planet: planet} do
      # astrophysics requires level 3 research lab, level 4 espionage tech, level 3 impulse drive
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      espionage_tech = Repo.one!(from r in Research, where: r.name == "Espionage Technology")

      impulse_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Impulse Engine Technology")

      astrophysics_tech =
        Repo.one!(from r in Research, where: r.name == "Astrophysics Technology")

      refute Planets.can_build_research?(planet, astrophysics_tech.id)

      # meet exact requirements
      set_player_research_level(planet.player_id, espionage_tech.id, 5)
      set_player_research_level(planet.player_id, impulse_drive_tech.id, 3)
      set_planet_building_level(planet.id, research_lab.id, 3)

      assert Planets.can_build_research?(planet, astrophysics_tech.id)
    end

    test "returns true when research prerequisites are exactly met (case 2)", %{planet: planet} do
      # intergalactic research network requires lvl 10 research lab, lvl 8 computer tech, lvl 8 hyperspace tech
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      computer_tech = Repo.one!(from r in Research, where: r.name == "Computer Technology")
      hyperspace_tech = Repo.one!(from r in Research, where: r.name == "Hyperspace Technology")

      research_network_tech =
        Repo.one!(from r in Research, where: r.name == "Intergalactic Research Network")

      refute Planets.can_build_research?(planet, research_network_tech.id)

      # meet exact requirements
      set_player_research_level(planet.player_id, computer_tech.id, 8)
      set_player_research_level(planet.player_id, hyperspace_tech.id, 8)
      set_planet_building_level(planet.id, research_lab.id, 10)

      assert Planets.can_build_research?(planet, research_network_tech.id)
    end

    test "returns true when research prerequisites are more than met (case 1)", %{planet: planet} do
      # plasma tech requires lvl 4 research lab, lvl 8 energy tech, lvl 10 laser tech, lvl 5 ion
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      laser_tech = Repo.one!(from r in Research, where: r.name == "Laser Technology")
      ion_tech = Repo.one!(from r in Research, where: r.name == "Ion Technology")
      plasma_tech = Repo.one!(from r in Research, where: r.name == "Plasma Technology")

      refute Planets.can_build_research?(planet, plasma_tech.id)

      # exceed requirements
      set_player_research_level(planet.player_id, ion_tech.id, 20)
      set_player_research_level(planet.player_id, energy_tech.id, 30)
      set_player_research_level(planet.player_id, laser_tech.id, 40)
      set_planet_building_level(planet.id, research_lab.id, 50)

      assert Planets.can_build_research?(planet, plasma_tech.id)
    end

    test "returns true when research prerequisites are more than met (case 2)", %{planet: planet} do
      # ion tech requires lvl 4 research lab, lvl 4 energy tech, lvl 5 laser tech
      research_lab = Repo.one!(from b in Building, where: b.name == "Research Lab")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      laser_tech = Repo.one!(from r in Research, where: r.name == "Laser Technology")
      ion_tech = Repo.one!(from r in Research, where: r.name == "Ion Technology")

      refute Planets.can_build_research?(planet, ion_tech.id)

      # exceed requirements
      set_player_research_level(planet.player_id, energy_tech.id, 30)
      set_player_research_level(planet.player_id, laser_tech.id, 40)
      set_planet_building_level(planet.id, research_lab.id, 50)

      assert Planets.can_build_research?(planet, ion_tech.id)
    end
  end

  describe "can_build_unit?/2" do
    test "returns false when there are multiple missing prerequisites", %{planet: planet} do
      # battleship requires lvl 7 shipyard, lvl 4 hyperspace drive
      battleship = Repo.one!(from u in Unit, where: u.name == "Battleship")

      hyperspace_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Hyperspace Engine Technology")

      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")

      # no requirements are met
      set_planet_building_level(planet.id, shipyard.id, 6)
      set_player_research_level(planet.player_id, hyperspace_drive_tech.id, 3)

      refute Planets.can_build_unit?(planet, battleship.id)
    end

    test "returns false when there are missing prerequisites (research)", %{planet: planet} do
      # cruiser requires lvl 5 shipyard, lvl 4 impulse drive, lvl 2 ion tech
      cruiser = Repo.one!(from u in Unit, where: u.name == "Cruiser")

      impulse_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Impulse Engine Technology")

      ion_tech = Repo.one!(from r in Research, where: r.name == "Ion Technology")
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")

      # meet building requirements only
      set_planet_building_level(planet.id, shipyard.id, 6)
      set_player_research_level(planet.player_id, impulse_drive_tech.id, 5)
      set_player_research_level(planet.player_id, ion_tech.id, 1)

      refute Planets.can_build_unit?(planet, cruiser.id)
    end

    test "returns false when there are missing prerequisites (buildings)", %{planet: planet} do
      # recycler requires lvl 4 shipyard, lvl 6 combustion drive, lvl 2 shield tech
      recycler = Repo.one!(from u in Unit, where: u.name == "Recycler")

      combustion_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Combustion Engine Technology")

      shields_tech = Repo.one!(from r in Research, where: r.name == "Shields Technology")
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")

      # meet research requirements only
      set_planet_building_level(planet.id, shipyard.id, 3)
      set_player_research_level(planet.player_id, combustion_drive_tech.id, 10)
      set_player_research_level(planet.player_id, shields_tech.id, 10)

      refute Planets.can_build_unit?(planet, recycler.id)
    end

    test "returns true when research prerequisites are exactly met (case 1)", %{planet: planet} do
      # gauss cannon requires lvl 6 shipyard, lvl 6 energy tech, lvl 3 weapons tech, lvl 1 shields tech
      gauss_cannon = Repo.one!(from u in Unit, where: u.name == "Gauss Cannon")
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")
      energy_tech = Repo.one!(from r in Research, where: r.name == "Energy Technology")
      weapons_tech = Repo.one!(from r in Research, where: r.name == "Weapons Technology")
      shields_tech = Repo.one!(from r in Research, where: r.name == "Shields Technology")

      refute Planets.can_build_unit?(planet, gauss_cannon.id)

      # meet exact requirements
      set_player_research_level(planet.player_id, energy_tech.id, 6)
      set_player_research_level(planet.player_id, weapons_tech.id, 3)
      set_player_research_level(planet.player_id, shields_tech.id, 1)
      set_planet_building_level(planet.id, shipyard.id, 6)

      assert Planets.can_build_unit?(planet, gauss_cannon.id)
    end

    test "returns true when research prerequisites are exactly met (case 2)", %{planet: planet} do
      # heavy fighter requires lvl 3 shipyard, lvl 2 armor tech, lvl 2 impulse drive
      heavy_fighter = Repo.one!(from u in Unit, where: u.name == "Heavy Fighter")
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")

      impulse_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Impulse Engine Technology")

      armor_tech = Repo.one!(from r in Research, where: r.name == "Armor Technology")

      refute Planets.can_build_unit?(planet, heavy_fighter.id)

      # meet exact requirements
      set_player_research_level(planet.player_id, impulse_drive_tech.id, 2)
      set_player_research_level(planet.player_id, armor_tech.id, 2)
      set_planet_building_level(planet.id, shipyard.id, 3)

      assert Planets.can_build_unit?(planet, heavy_fighter.id)
    end

    test "returns true when research prerequisites are more than met (case 1)", %{planet: planet} do
      # deathstar requires lvl 12 shipyard, lvl 1 graviton tech, lvl 7 hyperspace drive, lvl 6 hyperspace tech
      deathstar = Repo.one!(from u in Unit, where: u.name == "Deathstar")
      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")
      graviton_tech = Repo.one!(from r in Research, where: r.name == "Graviton Technology")

      hyperspace_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Hyperspace Engine Technology")

      hyperspace_tech = Repo.one!(from r in Research, where: r.name == "Hyperspace Technology")

      refute Planets.can_build_unit?(planet, deathstar.id)

      # exceed requirements
      set_player_research_level(planet.player_id, graviton_tech.id, 5)
      set_player_research_level(planet.player_id, hyperspace_drive_tech.id, 15)
      set_player_research_level(planet.player_id, hyperspace_tech.id, 25)
      set_planet_building_level(planet.id, shipyard.id, 20)

      assert Planets.can_build_unit?(planet, deathstar.id)
    end

    test "returns true when research prerequisites are more than met (case 2)", %{planet: planet} do
      # interplanetary missile requires lvl 1 shipyard, lvl 4 missile silo, lvl 1 impulse drive
      interplanetary_missile =
        Repo.one!(from u in Unit, where: u.name == "Interplanetary Missile")

      shipyard = Repo.one!(from b in Building, where: b.name == "Shipyard")
      missile_silo = Repo.one!(from b in Building, where: b.name == "Missile Silo")

      impulse_drive_tech =
        Repo.one!(from r in Research, where: r.name == "Impulse Engine Technology")

      refute Planets.can_build_unit?(planet, interplanetary_missile.id)

      # exceed requirements
      set_player_research_level(planet.player_id, impulse_drive_tech.id, 15)
      set_planet_building_level(planet.id, shipyard.id, 30)
      set_planet_building_level(planet.id, missile_silo.id, 25)

      assert Planets.can_build_unit?(planet, interplanetary_missile.id)
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

  defp set_planet_building_level(planet_id, building_id, level) do
    from(pb in PlanetBuilding,
      where: pb.planet_id == ^planet_id and pb.building_id == ^building_id,
      update: [set: [level: ^level]]
    )
    |> Repo.update_all([])
  end

  defp set_player_research_level(player_id, research_id, level) do
    from(pr in PlayerResearch,
      where: pr.player_id == ^player_id and pr.research_id == ^research_id,
      update: [set: [level: ^level]]
    )
    |> Repo.update_all([])
  end
end
