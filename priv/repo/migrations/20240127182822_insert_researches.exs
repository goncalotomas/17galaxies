defmodule Galaxies.Repo.Migrations.InsertResearches do
  use Ecto.Migration

  alias Galaxies.Repo
  alias Galaxies.Research

  def change do
    now = DateTime.utc_now()

    Repo.insert_all(
      Research,
      [
        %{
          id: 1,
          name: "Espionage Technology",
          list_order: 10,
          image_src: "/images/researches/espionage.webp",
          upgrade_cost_formula: "200 * 2^(level - 1)$1000 * 2^(level - 1)$200 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description:
            "As the level of this technique increases, more detailed information can be obtained from spying missions, while enemy spy probes can collect less information from your planets.",
          long_description:
            "Espionage Technology is, in the first instance, an advancement of sensor technology. The more advanced this technology is, the more information the user receives about activities in his environment. The differences between your own spy level and opposing spy levels is crucial for probes. The more advanced your own espionage technology is, the more information the report can gather and the smaller the chance is that your espionage activities are discovered. The more probes that you send on one mission, the more details they can gather from the target planet. But at the same time it also increases the chance of discovery.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 2,
          name: "Computer Technology",
          list_order: 20,
          image_src: "/images/researches/computer.webp",
          upgrade_cost_formula: "0$400 * 2^(level - 1)$600 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the maximum fleet slot by 1.",
          long_description:
            "Once launched on any mission, fleets are controlled primarily by a series of computers located on the originating planet. These massive computers calculate the exact time of arrival, controls course corrections as needed, calculates trajectories, and regulates flight speeds. With each level researched, the flight computer is upgraded to allow an additional slot to be launched. Computer technology should be continuously developed throughout the building of your empire.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 3,
          name: "Energy Technology",
          list_order: 30,
          image_src: "/images/researches/energy.webp",
          upgrade_cost_formula: "0$800 * 2^(level - 1)$400 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases energy production by 2%.",
          long_description:
            "As various fields of research advanced, it was discovered that the current technology of energy distribution was not sufficient enough to begin certain specialized research. With each upgrade of your Energy Technology, new research can be conducted which unlocks development of more sophisticated ships and defences.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 4,
          name: "Laser Technology",
          list_order: 40,
          image_src: "/images/researches/laser.webp",
          upgrade_cost_formula: "200 * 2^(level - 1)$100 * 2^(level - 1)$0$0",
          upgrade_time_formula: "5",
          short_description: "Increases the attack power of laser weapons by 1%.",
          long_description:
            "Lasers (light amplification by stimulated emission of radiation) produce an intense, energy rich emission of coherent light. These devices can be used in all sorts of areas, from optical computers to heavy laser weapons, which effortlessly cut through armour technology. The laser technology provides an important basis for research of other weapon technologies.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 5,
          name: "Ion Technology",
          list_order: 50,
          image_src: "/images/researches/ion.webp",
          upgrade_cost_formula: "1000 * 2^(level - 1)$300 * 2^(level - 1)$100 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the attack power of ion weapons by 1%.",
          long_description:
            "Ions can be concentrated and accelerated into a deadly beam. These beams can then inflict enormous damage. Our scientists have also developed a technique that will clearly reduce the deconstruction costs for buildings and systems.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 6,
          name: "Plasma Technology",
          list_order: 60,
          image_src: "/images/researches/plasma.webp",
          upgrade_cost_formula:
            "2000 * 2^(level - 1)$4000 * 2^(level - 1)$1000 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the attack power of plasma weapons by 1%.",
          long_description:
            "A further development of ion technology that doesn`t speed up ions but high-energy plasma instead, which can then inflict devastating damage on impact with an object.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 7,
          name: "Graviton Technology",
          list_order: 70,
          image_src: "/images/researches/graviton.webp",
          upgrade_cost_formula: "0$0$0$300000 * 3^(level - 1)",
          upgrade_time_formula: "5",
          short_description: "Increases the attack power of graviton weapons by 2%.",
          long_description:
            "A graviton is an elementary particle that is massless and has no cargo. It determines the gravitational power. By firing a concentrated load of gravitons, an artificial gravitational field can be constructed. Not unlike a black hole, it draws mass into itself. Thus it can destroy ships and even entire moons. To produce a sufficient amount of gravitons, huge amounts of energy are required. Graviton Research is required to construct a destructive Deathstar.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 8,
          name: "Weapons Technology",
          list_order: 80,
          image_src: "/images/researches/weapons.webp",
          upgrade_cost_formula: "800 * 2^(level - 1)$200 * 2^(level - 1)$0$0",
          upgrade_time_formula: "5",
          short_description: "Increases the attack power of all units by 10%.",
          long_description:
            "Weapons Technology is a key research technology and is critical to your survival against enemy Empires. With each level of Weapons Technology researched, the weapons systems on ships and your defence mechanisms become increasingly more efficient. Each level increases the base strength of your weapons by 10% of the base value.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 9,
          name: "Shields Technology",
          list_order: 90,
          image_src: "/images/researches/shield.webp",
          upgrade_cost_formula: "200 * 2^(level - 1)$600 * 2^(level - 1)$0$0",
          upgrade_time_formula: "5",
          short_description: "Increases the shield power of all units by 10%.",
          long_description:
            "With the invention of the magnetosphere generator, scientists learned that an artificial shield could be produced to protect the crew in space ships not only from the harsh solar radiation environment in deep space, but also provide protection from enemy fire during an attack. Once scientists finally perfected the technology, a magnetosphere generator was installed on all ships and defence systems. As the technology is advanced to each level, the magnetosphere generator is upgraded which provides an additional 10% strength to the shields base value.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 10,
          name: "Armor Technology",
          list_order: 100,
          image_src: "/images/researches/armor.webp",
          upgrade_cost_formula: "1000 * 2^(level - 1)$0$0$0",
          upgrade_time_formula: "5",
          short_description: "Increases the armor power of all units by 10%.",
          long_description:
            "The environment of deep space is harsh. Pilots and crew on various missions not only faced intense solar radiation, they also faced the prospect of being hit by space debris, or destroyed by enemy fire in an attack. With the discovery of an aluminum-lithium titanium carbide alloy, which was found to be both light weight and durable, this afforded the crew a certain degree of protection. With each level of Armour Technology developed, a higher quality alloy is produced, which increases the armours strength by 10%.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 11,
          name: "Hyperspace Technology",
          list_order: 110,
          image_src: "/images/researches/hyperspace.webp",
          upgrade_cost_formula: "0$4000 * 2^(level - 1)$2000 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description:
            "Hyperspace technology increases expedition and asteroid mining gains by 1%.",
          long_description:
            "In theory, the idea of hyperspace travel relies on the existence of a separate and adjacent dimension. When activated, a hyperspace drive shunts the starship into this other dimension, where it can cover vast distances in an amount of time greatly reduced from the time it would take in \"normal\" space. Once it reaches the point in hyperspace that corresponds to its destination in real space, it re-emerges.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 12,
          name: "Combustion Engine Technology",
          list_order: 120,
          image_src: "/images/researches/combustion.webp",
          upgrade_cost_formula: "400 * 2^(level - 1)$0$600 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the speed of all ships using a combustion engine by 10%.",
          long_description:
            "The Combustion Drive is the oldest of technologies, but is still in use. With the Combustion Drive, exhaust is formed from propellants carried within the ship prior to use. In a closed chamber, the pressures are equal in each direction and no acceleration occurs. If an opening is provided at the bottom of the chamber then the pressure is no longer opposed on that side. The remaining pressure gives a resultant thrust in the side opposite the opening, which propels the ship forward by expelling the exhaust rearwards at extreme high speed.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 13,
          name: "Impulse Engine Technology",
          list_order: 130,
          image_src: "/images/researches/impulse.webp",
          upgrade_cost_formula: "2000 * 2^(level - 1)$4000 * 2^(level - 1)$600 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the speed of all ships using a impulse engine by 20%.",
          long_description:
            "The impulse drive is based on the recoil principle, by which the stimulated emission of radiation is mainly produced as a waste product from the core fusion to gain energy.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 14,
          name: "Hyperspace Engine Technology",
          list_order: 140,
          image_src: "/images/researches/warp.webp",
          upgrade_cost_formula:
            "10000 * 2^(level - 1)$20000 * 2^(level - 1)$6000 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description: "Increases the speed of all ships using a hyperspace engine by 30%.",
          long_description:
            "Long distances can be covered very quickly due to the curvature of the immediate vicinity of the ship. The more developed the hyperspace propellant, the greater the curvature of space.",
          inserted_at: now,
          updated_at: now
        },
        # %{
        #   id: 15,
        #   name: "Cargo Technology",
        #   list_order: 150,
        #   image_src: "/images/researches/cargo.webp",
        #   upgrade_cost_formula: "200 * 2^(level - 1)$1000 * 2^(level - 1)$200 * 2^(level - 1)$0",
        #   upgrade_time_formula: "5",
        #   short_description:
        #     "Increases the cargo capacity of Cargo ships by 50% and increases the cargo capacity of all other ships by 5%.",
        #   long_description:
        #     "As the empire's need for resources grows, shipping costs increase at the same rate. Scientists have been working on reducing resource costs for many years, and eventually they were able to make cargo technology what it is today. Each level of this technology greatly increases the carrying capacity of cargo ships, while increasing the shipping capacity of all other ships.",
        #   inserted_at: now,
        #   updated_at: now
        # },
        %{
          id: 15,
          name: "Astrophysics Technology",
          list_order: 160,
          image_src: "/images/researches/astrophysics.webp",
          upgrade_cost_formula:
            "4000 * 1.75^(level - 1)$8000 * 1.75^(level - 1)$4000 * 1.75^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description:
            "This technology allows you to colonize new planets and increase the maximum number of expedition missions.",
          long_description:
            "Further findings in the field of astrophysics allow for the construction of laboratories that can be fitted on more and more ships. This makes long expeditions far into unexplored areas of space possible. In addition these advancements can be used to further colonise the universe. For every two levels of this technology an additional planet can be made usable.",
          inserted_at: now,
          updated_at: now
        },
        %{
          id: 16,
          name: "Intergalactic Research Network",
          list_order: 170,
          image_src: "/images/researches/intergalactic-research-network.webp",
          upgrade_cost_formula:
            "240000 * 2^(level - 1)$400000 * 2^(level - 1)$160000 * 2^(level - 1)$0",
          upgrade_time_formula: "5",
          short_description:
            "Scientific research laboratories on different planets connect to each other and increasing the speed of research.",
          long_description:
            "When research is getting more and more complex scientists are revolutionary to connect individual laboratories developed a path: Intergalactic Research Network! Central computers of research stations via this network they connect directly with each other, which speeds up research. A research laboratory is connected for each level researched. Always here laboratories with the highest level are added. The networked lab is should be developed sufficiently to carry out independently. All participating laboratories expansion stages meet in intergalactic research network was introduced.",
          inserted_at: now,
          updated_at: now
          # },
          # %{
          #   id: 17,
          #   name: "Mineral Extration Technology",
          #   image_src: "/images/researches/.webp",
          #   short_description: "Increases metal mine production on all planets.",
          #   long_description:
          #     "Since metal is the most widely used resource in the industry, efforts have been made to increase production power. As a result of using the raw resources processed in metal mines more effectively, metal production power also increases considerably."
          # },
          # %{
          #   id: 17,
          #   name: "Crystallization Technology",
          #   image_src: "/images/researches/.webp",
          #   short_description: "Increases crystal mine production on all planets.",
          #   long_description:
          #     "Since crystals are frangible, processing and using them require great skill. As the industry's need for crystals increases, efforts are being made to avoid wasting crystals."
          # },
          # %{
          #   id: 18,
          #   name: "Fuel Cell Technology",
          #   image_src: "/images/researches/.webp",
          #   short_description: "Increases deuterium production on all planets.",
          #   long_description:
          #     "Since Deuterium deposits are mostly under the sea, removing and storing them requires great efforts. Some of the deuterium may become unusable during this process. Scientists are working to use these resources more effectively in many fields. The amount of raw deuterium required decreases as fuel technology improves."
        }
      ]
    )
  end
end
