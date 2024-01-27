defmodule Galaxies.Repo.Migrations.InsertBuildings do
  use Ecto.Migration

  alias Galaxies.Repo
  alias Galaxies.Building

  def change do
    now = DateTime.utc_now()

    Repo.insert_all(Building, [
      %{
        name: "Metal Mine",
        list_order: 10,
        image_src: "/images/buildings/metal-mine-v3.webp",
        upgrade_cost_formula: "60 * 1.5^(level - 1)$15 * 1.5^(level - 1)$0$0",
        short_description:
          "The metal mine allows the extraction of raw metal from the planet. Metal production increases as the structure level increases. Once the metal storages are fully filled, metal production on the planet is also stopped. Metal mine needs energy to operate.",
        long_description:
          "Metal is a basic resource put to the foundation of your empire. With increasing of metal production, more resources can be used in construction of buildings, ships, rocket complexes and scientific researches is produced. Deep mines, require more energy for maximum production of metal. As metal is the most common of all present resources, the manufacturing cost is considered the lowest of all resources for trade and exchange.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Crystal Mine",
        list_order: 20,
        image_src: "/images/buildings/crystal-mine.webp",
        upgrade_cost_formula: "48 * 1.6^(level - 1)$24 * 1.6^(level - 1)$0$0",
        short_description:
          "The metal mine allows the extraction of raw metal from the planet. Metal production increases as the structure level increases. Once the metal storages are fully filled, metal production on the planet is also stopped. Metal mine needs energy to operate.",
        long_description:
          "Metal is a basic resource put to the foundation of your empire. With increasing of metal production, more resources can be used in construction of buildings, ships, rocket complexes and scientific researches is produced. Deep mines, require more energy for maximum production of metal. As metal is the most common of all present resources, the manufacturing cost is considered the lowest of all resources for trade and exchange.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Deuterium Refinery",
        list_order: 30,
        image_src: "/images/buildings/deuterium-refinery-v3.webp",
        upgrade_cost_formula: "225 * 1.5^(level - 1)$75 * 1.5^(level - 1)$0$0",
        short_description:
          "Deuterium synthesizer provides the extraction of deuterium from the planet. The deuterium production increases as the structure level increases. Once the deuterium tanks are fully filled, deuterium production on the planet is also stopped. Deuterium synthesizer needs energy to operate.",
        long_description:
          "The rare deuterium is a natural isotope of hydrogen. The extraction of the so-called \"heavy hydrogen\" from the world's oceans is very expensive, but as an essential fuel it provides the basic prerequisite for nuclear fusion. As an highly exothermic fuel, deuterium is significantly more efficient than other fossil fuels. As a result, long times ago effective drives for spaceships could be designed for the first time, which are still used today. Deuterium is also required to protect the sensor phalanx from overheating and to enable research into complex technologies.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Solar Power Plant",
        list_order: 40,
        image_src: "/images/buildings/solar-power-plant.webp",
        upgrade_cost_formula: "75 * 1.5^(level - 1)$30 * 1.5^(level - 1)$0$0",
        short_description:
          "Solar power plants are huge structures that produce energy using solar rays. They contribute to the energy production of the planet and helps the operation of the mines.",
        long_description:
          "Huge solar panels reflect incoming solar energy to a liquid-filled core. This passes on the energy gained through heating to a water cycle. Turbines can be driven by evaporation, which ultimately generate electricity. A planet's proximity to the sun actually doesn't matter in solar power plants, as the technology is limited by the efficiency of water evaporation. An increase in the surface area of the parabolic mirrors leads to an increase in energy production in the power grids. Another advantage is the indestructibility of the facility by enemy fleet attacks.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Fusion Reactor",
        list_order: 50,
        image_src: "/images/buildings/fusion-reactor.webp",
        upgrade_cost_formula:
          "900 * 1.8^(level - 1)$360 * 1.8^(level - 1)$180 * 1.8^(level - 1)$0",
        short_description:
          "Fusion reactors are plants that produce radioactive energy using fusion technology. They contribute to the energy production of the planet and helping the operation of the mines. Fusion reactors need deuterium to work and use some of the deuterium production on the planet.",
        long_description:
          "In fusion reactors, deuterium and tritium nuclei are fused together at high speeds. Nuclear fusion thus represents the reversal of nuclear fission, so to speak. The fusion of both atomic nuclei leads to the formation of a helium nucleus and the emission of a high-energy neutron. Merely through the fusion of an atom, 17.6 MeV (mega-electron volts) can already be released. With constant expansion of the reactor, it can make a significant contribution to the energy supply of the planet. In contrast to the fragile solar satellites, this form of energy supply cannot be destroyed by attacks. Deuterium consumption during nuclear fusion can be made more efficient as scientists delve further into energy engineering.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Metal Storage",
        list_order: 60,
        image_src: "/images/buildings/metal-storage.webp",
        upgrade_cost_formula: "500 * 2^level$0$0$0",
        short_description:
          "Metal storages are structures used to store metal resources on the planet. Once the metal storages are fully filled, metal production on the planet is also stopped.",
        long_description:
          "This storage facility is used for storage of metal ores. Each level of update increases the amount of ore which can be preserved. If volume of the storage facility is exceeded, production of metal ceases automatically, in order to prevent a disastrous cave-in in mines pits.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Crystal Storage",
        list_order: 70,
        upgrade_cost_formula: "500 * 2^level$250 * 2^level$0$0",
        image_src: "/images/buildings/crystal-storage.webp",
        short_description:
          "Crystal storages are used to store crystal resources on the planet. Once the crystal storages are fully filled, crystal production on the planet is also stopped.",
        long_description:
          "Raw crystal is stored in the buildings of this type. With each level of the storage facility, the amount of crystal is increased which will be preserved. As soon as production exceeds an admissible capacity, production of crystal ceases automatically, in order to prevent collapse in pits.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Deuterium Tank",
        list_order: 80,
        image_src: "/images/buildings/deuterium-tank-v4.webp",
        upgrade_cost_formula: "500 * 2^level$500 * 2^level$0$0",
        short_description:
          "Deuterium tanks are structures used to store deuterium resources on the planet. Once the deuterium tanks are fully filled, deuterium production on the planet is also stopped.",
        long_description:
          "Is intended for storage of again synthesized deuterium. After processing in the synthesizer, deuterium in tubes enters this reservoir for subsequent use. With each level of the storage facility construction communicating capacity is increased. As soon as critical mark will be reached, synthesizer is switched off to prevent breakage of the reservoir.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Robot Factory",
        list_order: 90,
        image_src: "/images/buildings/robot-factory.webp",
        upgrade_cost_formula: "400 * 2^(level - 1)$120 * 2^(level - 1)$200 * 2^(level - 1)$0",
        short_description:
          "Robot Factories are facilities that produce construction robots that greatly speed up the upgrade of buildings, facilities, ships, and defenses per level.",
        long_description:
          "The robot factory is named after the production of highly developed robots. These support the colonists in the expansion of the planet and thus shorten the construction times enormously. Slightly faster robots are developed in each new level of the factory, further reducing the time required for the construction of buildings, plants, ships and defenses.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Nanite Factory",
        list_order: 100,
        image_src: "/images/buildings/nanite-factory.webp",
        upgrade_cost_formula:
          "1000000 * 2^(level - 1)$500000 * 2^(level - 1)$100000 * 2^(level - 1)$0",
        short_description:
          "Nanite factory; manufactures nanometric robots that helps construction of building, ship and defense units. Each level of this facility increases the production speed of buildings, ships and defense units by 80%.",
        long_description:
          "Nanite factories greatly speed up the completion of buildings, ships, and defenses using nanometric bots. The microscopically small machines represent the culmination of robotics. For a meaningful use of the nanobots it was necessary to develop tiny processors beforehand, so the computer technology had to be mastered before building them.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Shipyard",
        list_order: 110,
        image_src: "/images/buildings/hangar.webp",
        upgrade_cost_formula: "400 * 2^(level - 1)$200 * 2^(level - 1)$100 * 2^(level - 1)$0",
        short_description:
          "Shipyards are facilities where ships and defense units are produced. As the shipyard level increases, the time required to manufacture ships and defense units decreases.",
        long_description:
          "Shipyards are responsible for creation of spacecrafts and defence units. At increase of the level, the shipyard can produce more advanced transport and fighting vessels on much greater speed.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Research Lab",
        list_order: 120,
        image_src: "/images/buildings/research-lab.webp",
        upgrade_cost_formula: "200 * 2^(level - 1)$400 * 2^(level - 1)$200 * 2^(level - 1)$0",
        short_description:
          "With the help of these facilities, the scientific capabilities of the Empire are constantly being improved. Due to the expansion, new opportunities for researching even more complex technologies are constantly being released. As the level of this facility increases, so does the speed of scientific research.",
        long_description:
          "Important part of any empire are research laboratories, where they are improved old and new openings of science are studied. With each level of construction, speed, with which new technologies are investigated, is increased. So that to conduct researches as soon as possible, scientific empires are directed to given planet. In such a manner, knowledges of new technologies extend easily to the whole empire.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Terraformer",
        list_order: 130,
        image_src: "/images/buildings/terraformer.webp",
        upgrade_cost_formula: "0$50000 * 2^(level - 1)$100000 * 2^(level - 1)$0",
        short_description:
          "Terraformer ensures that unusable lands on the planet are improved and put into use. Each level of this facility opens 6 new areas.",
        long_description:
          "The steady subjugation of the planet inevitably leads to scarce useable space. The reckless increase in production capacity and the consequent pollution of the atmosphere could soon consume the rest of the planet's living space. Scientists therefore developed a method to convert fallow land into usable space using large amounts of energy. Each stage of expansion guarantees +6 new fields, of which 1 field is already required for the terraformer.",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Missile Silo",
        list_order: 140,
        image_src: "/images/buildings/missile-silo.webp",
        upgrade_cost_formula:
          "20000 * 2^(level - 1)$20000 * 2^(level - 1)$1000 * 2^(level - 1)$0",
        short_description:
          "Missile silos are facilities that produce and store interplanetary missiles and interceptors. As the structure level increases, the number of storable missiles increases.",
        long_description:
          "Missile silos are used to build, store and run interplanetary missiles and missile interceptors. With each level of the mine, the number of missiles increases proportionately. Interplanetary missiles and missile interceptors are stored in the same bunker.",
        inserted_at: now,
        updated_at: now
      }
    ])
  end
end
