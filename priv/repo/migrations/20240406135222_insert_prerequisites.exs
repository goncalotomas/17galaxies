defmodule Galaxies.Repo.Migrations.InsertPrerequisites do
  @moduledoc """
  Sets up the data for building prerequisites for buildings, units and researches.
  Uses data from the original game.
  For readability and maintainability, buildings are fetched and then used by name.

  """

  alias Galaxies.Building
  alias Galaxies.Repo
  alias Galaxies.Research
  alias Galaxies.Unit

  alias Galaxies.Prerequisites.BuildingPrerequisiteBuilding
  alias Galaxies.Prerequisites.BuildingPrerequisiteResearch
  alias Galaxies.Prerequisites.ResearchPrerequisiteBuilding
  alias Galaxies.Prerequisites.ResearchPrerequisiteResearch
  alias Galaxies.Prerequisites.UnitPrerequisiteBuilding
  alias Galaxies.Prerequisites.UnitPrerequisiteResearch

  use Ecto.Migration

  import Ecto.Query

  def change do
    # get buildings that have prerequisites or that are used as prerequisites
    buildings = Repo.all(Building)
    deuterium_synthesizer = Enum.find(buildings, fn b -> b.name == "Deuterium Synthesizer" end)
    fusion_reactor = Enum.find(buildings, fn b -> b.name == "Fusion Reactor" end)
    robot_factory = Enum.find(buildings, fn b -> b.name == "Robot Factory" end)
    nanite_factory = Enum.find(buildings, fn b -> b.name == "Nanite Factory" end)
    shipyard = Enum.find(buildings, fn b -> b.name == "Shipyard" end)
    research_lab = Enum.find(buildings, fn b -> b.name == "Research Lab" end)
    missile_silo = Enum.find(buildings, fn b -> b.name == "Missile Silo" end)
    terraformer = Enum.find(buildings, fn b -> b.name == "Terraformer" end)

    # get researches that have prerequisites or that are used as prerequisites (all of them)
    researches = Repo.all(Research)
    energy_tech = Enum.find(researches, fn r -> r.name == "Energy Technology" end)
    computer_tech = Enum.find(researches, fn r -> r.name == "Computer Technology" end)
    hyperspace_tech = Enum.find(researches, fn r -> r.name == "Hyperspace Technology" end)
    laser_tech = Enum.find(researches, fn r -> r.name == "Laser Technology" end)
    ion_tech = Enum.find(researches, fn r -> r.name == "Ion Technology" end)
    plasma_tech = Enum.find(researches, fn r -> r.name == "Plasma Technology" end)
    armor_tech = Enum.find(researches, fn r -> r.name == "Armor Technology" end)
    shield_tech = Enum.find(researches, fn r -> r.name == "Shields Technology" end)
    weapons_tech = Enum.find(researches, fn r -> r.name == "Weapons Technology" end)
    espionage_tech = Enum.find(researches, fn r -> r.name == "Espionage Technology" end)
    astrophysics_tech = Enum.find(researches, fn r -> r.name == "Astrophysics Technology" end)

    intergalactic_research_network_tech =
      Enum.find(researches, fn r -> r.name == "Intergalactic Research Network" end)

    graviton_tech = Enum.find(researches, fn r -> r.name == "Graviton Technology" end)

    combustion_drive_tech =
      Enum.find(researches, fn r -> r.name == "Combustion Engine Technology" end)

    impulse_drive_tech = Enum.find(researches, fn r -> r.name == "Impulse Engine Technology" end)

    hyperspace_drive_tech =
      Enum.find(researches, fn r -> r.name == "Hyperspace Engine Technology" end)

    # get units that have prerequisites (all of them)
    units = Repo.all(Unit)
    light_fighter = Enum.find(units, fn u -> u.name == "Light Fighter" end)
    heavy_fighter = Enum.find(units, fn u -> u.name == "Heavy Fighter" end)
    cruiser = Enum.find(units, fn u -> u.name == "Cruiser" end)
    battleship = Enum.find(units, fn u -> u.name == "Battleship" end)
    interceptor = Enum.find(units, fn u -> u.name == "Interceptor" end)
    bomber = Enum.find(units, fn u -> u.name == "Bomber" end)
    destroyer = Enum.find(units, fn u -> u.name == "Destroyer" end)
    deathstar = Enum.find(units, fn u -> u.name == "Deathstar" end)
    reaper = Enum.find(units, fn u -> u.name == "Reaper" end)
    small_cargo = Enum.find(units, fn u -> u.name == "Small Cargo Ship" end)
    large_cargo = Enum.find(units, fn u -> u.name == "Large Cargo Ship" end)
    colony_ship = Enum.find(units, fn u -> u.name == "Colony Ship" end)
    recycler = Enum.find(units, fn u -> u.name == "Recycler" end)
    espionage_probe = Enum.find(units, fn u -> u.name == "Espionage Probe" end)
    solar_satellite = Enum.find(units, fn u -> u.name == "Solar Satellite" end)
    crawler = Enum.find(units, fn u -> u.name == "Crawler" end)
    rocket_launcher = Enum.find(units, fn u -> u.name == "Rocket Launcher" end)
    light_laser = Enum.find(units, fn u -> u.name == "Light Laser Turret" end)
    heavy_laser = Enum.find(units, fn u -> u.name == "Heavy Laser Turret" end)
    gauss_cannon = Enum.find(units, fn u -> u.name == "Gauss Cannon" end)
    ion_cannon = Enum.find(units, fn u -> u.name == "Ion Cannon" end)
    plasma_cannon = Enum.find(units, fn u -> u.name == "Plasma Cannon" end)
    small_shield = Enum.find(units, fn u -> u.name == "Small Shield Dome" end)
    large_shield = Enum.find(units, fn u -> u.name == "Large Shield Dome" end)
    anti_ballistic_missile = Enum.find(units, fn u -> u.name == "Interceptor Missile" end)
    interplanetary_missile = Enum.find(units, fn u -> u.name == "Interplanetary Missile" end)

    # actually insert prerequisites into appropriate tables

    # Insert buildings required for other buildings
    # e.g. Fusion reactor requires a level 5 Deuterium Synthesizer
    Repo.insert_all(BuildingPrerequisiteBuilding, [
      %{
        building_id: fusion_reactor.id,
        prerequisite_building_id: deuterium_synthesizer.id,
        prerequisite_building_level: 5
      },
      %{
        building_id: nanite_factory.id,
        prerequisite_building_id: robot_factory.id,
        prerequisite_building_level: 10
      },
      %{
        building_id: shipyard.id,
        prerequisite_building_id: robot_factory.id,
        prerequisite_building_level: 2
      },
      %{
        building_id: missile_silo.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        building_id: terraformer.id,
        prerequisite_building_id: nanite_factory.id,
        prerequisite_building_level: 1
      }
    ])

    # Insert researches required for buildings
    # e.g. Fusion Reactor requires a level 3 Energy Technology
    Repo.insert_all(BuildingPrerequisiteResearch, [
      %{
        building_id: fusion_reactor.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 3
      },
      %{
        building_id: nanite_factory.id,
        prerequisite_research_id: computer_tech.id,
        prerequisite_research_level: 10
      },
      %{
        building_id: terraformer.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 12
      }
    ])

    # Insert buildings required for researches
    # e.g. Plasma Tech requires a level 4 Research Lab
    Repo.insert_all(ResearchPrerequisiteBuilding, [
      %{
        research_id: energy_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 1
      },
      %{
        research_id: laser_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 1
      },
      %{
        research_id: ion_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 4
      },
      %{
        research_id: hyperspace_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 7
      },
      %{
        research_id: plasma_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 4
      },
      %{
        research_id: espionage_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 3
      },
      %{
        research_id: computer_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 1
      },
      %{
        research_id: astrophysics_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 3
      },
      %{
        research_id: intergalactic_research_network_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 10
      },
      %{
        research_id: graviton_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 12
      },
      %{
        research_id: combustion_drive_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 1
      },
      %{
        research_id: impulse_drive_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 2
      },
      %{
        research_id: hyperspace_drive_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 7
      },
      %{
        research_id: weapons_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 4
      },
      %{
        research_id: shield_tech.id,
        prerequisite_building_id: research_lab.id,
        prerequisite_building_level: 6
      },
      %{
        research_id: armor_tech.id,
        prerequisite_building_id: energy_tech.id,
        prerequisite_building_level: 2
      }
    ])

    # Insert research required for other researches
    # e.g. Intergalactic Research Network requires a level 8 Hyperspace Tech.
    Repo.insert_all(ResearchPrerequisiteResearch, [
      %{
        research_id: laser_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 2
      },
      %{
        research_id: ion_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 4
      },
      %{
        research_id: ion_tech.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 5
      },
      %{
        research_id: hyperspace_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 5
      },
      %{
        research_id: hyperspace_tech.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 5
      },
      %{
        research_id: plasma_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 8
      },
      %{
        research_id: plasma_tech.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 10
      },
      %{
        research_id: plasma_tech.id,
        prerequisite_research_id: ion_tech.id,
        prerequisite_research_level: 5
      },
      %{
        research_id: astrophysics_tech.id,
        prerequisite_research_id: espionage_tech.id,
        prerequisite_research_level: 4
      },
      %{
        research_id: astrophysics_tech.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 3
      },
      %{
        research_id: intergalactic_research_network_tech.id,
        prerequisite_research_id: computer_tech.id,
        prerequisite_research_level: 8
      },
      %{
        research_id: intergalactic_research_network_tech.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 8
      },
      %{
        research_id: combustion_drive_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 1
      },
      %{
        research_id: impulse_drive_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 1
      },
      %{
        research_id: hyperspace_drive_tech.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 3
      },
      %{
        research_id: shield_tech.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 3
      }
    ])

    # Insert buildings required to build units.
    # e.g. A level 12 Shipyard is required to build Deathstars.
    Repo.insert_all(UnitPrerequisiteBuilding, [
      %{
        unit_id: light_fighter.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: heavy_fighter.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 3
      },
      %{
        unit_id: cruiser.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 5
      },
      %{
        unit_id: battleship.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 7
      },
      %{
        unit_id: interceptor.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 8
      },
      %{
        unit_id: bomber.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 8
      },
      %{
        unit_id: destroyer.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 9
      },
      %{
        unit_id: deathstar.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 12
      },
      %{
        unit_id: reaper.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 10
      },
      %{
        unit_id: small_cargo.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 2
      },
      %{
        unit_id: large_cargo.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 4
      },
      %{
        unit_id: colony_ship.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 4
      },
      %{
        unit_id: recycler.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 4
      },
      %{
        unit_id: espionage_probe.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 3
      },
      %{
        unit_id: solar_satellite.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: crawler.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 5
      },
      %{
        unit_id: rocket_launcher.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: light_laser.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 2
      },
      %{
        unit_id: heavy_laser.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 4
      },
      %{
        unit_id: gauss_cannon.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 6
      },
      %{
        unit_id: ion_cannon.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 4
      },
      %{
        unit_id: plasma_cannon.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 8
      },
      %{
        unit_id: small_shield.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: large_shield.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 6
      },
      %{
        unit_id: anti_ballistic_missile.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: anti_ballistic_missile.id,
        prerequisite_building_id: missile_silo.id,
        prerequisite_building_level: 2
      },
      %{
        unit_id: interplanetary_missile.id,
        prerequisite_building_id: shipyard.id,
        prerequisite_building_level: 1
      },
      %{
        unit_id: interplanetary_missile.id,
        prerequisite_building_id: missile_silo.id,
        prerequisite_building_level: 4
      }
    ])

    # Insert researches required to build units.
    # e.g. A level 1 Graviton Tech is required to build Deathstars.
    Repo.insert_all(UnitPrerequisiteResearch, [
      %{
        unit_id: light_fighter.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 1
      },
      %{
        unit_id: heavy_fighter.id,
        prerequisite_research_id: armor_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: heavy_fighter.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: cruiser.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: cruiser.id,
        prerequisite_research_id: ion_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: battleship.id,
        prerequisite_research_id: hyperspace_drive_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: interceptor.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 5
      },
      %{
        unit_id: interceptor.id,
        prerequisite_research_id: hyperspace_drive_tech.id,
        prerequisite_research_level: 5
      },
      %{
        unit_id: interceptor.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 12
      },
      %{
        unit_id: bomber.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: bomber.id,
        prerequisite_research_id: plasma_tech.id,
        prerequisite_research_level: 5
      },
      %{
        unit_id: destroyer.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 5
      },
      %{
        unit_id: destroyer.id,
        prerequisite_research_id: hyperspace_drive_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: deathstar.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: deathstar.id,
        prerequisite_research_id: hyperspace_drive_tech.id,
        prerequisite_research_level: 7
      },
      %{
        unit_id: deathstar.id,
        prerequisite_research_id: graviton_tech.id,
        prerequisite_research_level: 1
      },
      %{
        unit_id: reaper.id,
        prerequisite_research_id: hyperspace_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: reaper.id,
        prerequisite_research_id: hyperspace_drive_tech.id,
        prerequisite_research_level: 7
      },
      %{
        unit_id: reaper.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: small_cargo.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: large_cargo.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: colony_ship.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 3
      },
      %{
        unit_id: recycler.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: recycler.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: espionage_probe.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 3
      },
      %{
        unit_id: espionage_probe.id,
        prerequisite_research_id: espionage_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: crawler.id,
        prerequisite_research_id: combustion_drive_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: crawler.id,
        prerequisite_research_id: armor_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: crawler.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: light_laser.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 1
      },
      %{
        unit_id: light_laser.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 3
      },
      %{
        unit_id: heavy_laser.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 3
      },
      %{
        unit_id: heavy_laser.id,
        prerequisite_research_id: laser_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: gauss_cannon.id,
        prerequisite_research_id: energy_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: gauss_cannon.id,
        prerequisite_research_id: weapons_tech.id,
        prerequisite_research_level: 3
      },
      %{
        unit_id: gauss_cannon.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 1
      },
      %{
        unit_id: ion_cannon.id,
        prerequisite_research_id: ion_tech.id,
        prerequisite_research_level: 4
      },
      %{
        unit_id: plasma_cannon.id,
        prerequisite_research_id: plasma_tech.id,
        prerequisite_research_level: 7
      },
      %{
        unit_id: small_shield.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 2
      },
      %{
        unit_id: large_shield.id,
        prerequisite_research_id: shield_tech.id,
        prerequisite_research_level: 6
      },
      %{
        unit_id: interplanetary_missile.id,
        prerequisite_research_id: impulse_drive_tech.id,
        prerequisite_research_level: 1
      }
    ])
  end
end
