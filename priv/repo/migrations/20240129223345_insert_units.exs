defmodule Galaxies.Repo.Migrations.InsertUnits do
  use Ecto.Migration

  alias Galaxies.Repo

  def change do
    now = DateTime.utc_now()

    Repo.insert_all(Galaxies.Unit, [
      %{
        id: 101,
        name: "Light Fighter",
        list_order: 10,
        image_src: "/images/units/light-fighter.webp",
        short_description:
          "They are the most primitive warships of an empire. But when their number increases, they can easily destroy even huge ships.",
        long_description:
          "Light fighters are the most primitive warships of an empire. In large numbers, however, they manage to successfully confront even fleets composed of larger ships. Their low cost allows empires to create gigantic amounts of light fighters.",
        type: :ship,
        weapon_points: 50,
        shield_points: 10,
        hull_points: 400,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 102,
        name: "Heavy Fighter",
        list_order: 20,
        image_src: "/images/units/heavy-fighter.webp",
        short_description:
          "The constant further development of the light fighters finally made the production of the much more stable heavy fighters possible.",
        long_description:
          "The constant further development of the light fighters finally made it possible to produce significantly more stable ships. Due to the high proportion of crystals in development and a significant increase in fuel consumption, there are many empires that still cling to light fighters.",
        type: :ship,
        weapon_points: 150,
        shield_points: 25,
        hull_points: 1000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 103,
        name: "Cruiser",
        list_order: 30,
        image_src: "/images/units/cruiser.webp",
        short_description:
          "Due to their maneuverability and high speed, cruisers are a major challenge for enemy fleets and defenses.",
        long_description:
          "With further research into impulse engines, it was possible to far surpass the speed of the light and heavy fighters. It was time to declare war on the dominant fleets of fighters. Cruisers were therefore equipped with special ion cannons that could target multiple light fighters at the same time. Even in highly developed civilizations, cruisers are often used ships due to their maneuverability and high speed. They continue to pose a major challenge to enemy fighter fleets.",
        type: :ship,
        weapon_points: 400,
        shield_points: 50,
        hull_points: 2700,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 104,
        name: "Battleship",
        list_order: 40,
        image_src: "/images/units/battleship.webp",
        short_description:
          "Battleships are the backbone for early fleets, providing a high resistance to ships designed to overpower defenses during the first stages of new empires.",
        long_description:
          "Battleships are the backbone for early fleets, providing a high resistance to ships designed to overpower defenses during the first stages of new empires. Battleships have ample storage capacity making them the preferred choice for bringing back raw materials that have been plundered.",
        type: :ship,
        weapon_points: 1000,
        shield_points: 200,
        hull_points: 6000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 105,
        name: "Interceptor",
        list_order: 50,
        image_src: "/images/units/interceptor.webp",
        short_description:
          "Interceptors are very agile ships with sophisticated weapon systems. They were designed to counterbalance the prevailing battleships.",
        long_description:
          "Battlecruisers are very agile ships with sophisticated weapon systems. They were designed to counterbalance the prevailing battleships. However, their cargo space and fuel consumption are significantly smaller due to the revised design.",
        type: :ship,
        weapon_points: 700,
        shield_points: 400,
        hull_points: 7000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 106,
        name: "Bomber",
        list_order: 60,
        image_src: "/images/units/bombardier.webp",
        short_description:
          "Bombers are designed to destroy the enemy's defense line. Their concentrated bombardments are very strong against defensive units.",
        long_description:
          "It could be observed that some empires bunkered huge deposits of resources behind their defenses. Thanks to specialized plasma bombardments, even previously impregnable strongholds could be knocked out with almost no casualties. However, the heavy combat systems made the bomber very slow at the same time. Its weapon systems are designed to destroy geostationary guns, so that fights against other warships are mostly hopeless.",
        type: :ship,
        weapon_points: 1000,
        shield_points: 500,
        hull_points: 7500,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 107,
        name: "Destroyer",
        list_order: 70,
        image_src: "/images/units/dreadnaught.webp",
        short_description:
          "Destroyers are the most fearful of middle class warships due to their high shield strength and damage ability.",
        long_description:
          "Further exploration of hyperspace allowed empires to integrate entire arsenals into spaceships. These flying battle bases can only be stopped effectively by significantly larger ships. Due to their sheer size, the fuel consumption is double that of battleships. Due to the large number of weapon systems, the effective cargo hold has become even smaller at the same time. Destroyers are the most dangerous mid-tier warships due to their high shield strength and damage ability.",
        type: :ship,
        weapon_points: 2000,
        shield_points: 500,
        hull_points: 11_000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 108,
        name: "Reaper",
        list_order: 80,
        image_src: "/images/units/battleship-v3.webp",
        short_description:
          "The ability to collect debris fields immediately after battle has made this warship one of the most popular in the universe! They can directly collect a maximum of 40% of the total debris.",
        long_description:
          "The constant further development of the destroyers represented a change in the previous warfare. Reapers were not only clearly superior to previous ships in terms of their combat values. The integration of recycler technology also made it possible, to fill the generously dimensioned cargo hold directly after the battle with debris fields that had been created (up to 40% for own attacks / up to 100% for expedition-fights). Of course, this technology led to a sustained increase in numbers of these ships.",
        type: :ship,
        weapon_points: 2800,
        shield_points: 700,
        hull_points: 14_000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 109,
        name: "Deathstar",
        list_order: 90,
        image_src: "/images/units/juggernaut.webp",
        short_description:
          "The destructive power of Death Stars is unmatched. By focusing huge amounts of energy, the gigantic gravitational cannon can even destroy entire moons.",
        long_description:
          "The destructive power of Death Stars is unmatched. By focusing huge amounts of energy, the gigantic gravitational cannon can even destroy entire moons. However, there are rumors of imploding Death Stars, which can be traced back to overstressing the gravity cannon on moons that are too large. It's up to every empires leader to use this technology wisely. Their sheer size also makes the Death Stars very slow.",
        type: :ship,
        weapon_points: 12_000,
        shield_points: 16_000,
        hull_points: 900_000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 201,
        name: "Solar Satellite",
        list_order: 100,
        image_src: "/images/units/solar-satellite.webp",
        short_description:
          "Solar satellites are launched directly into the orbit of the respective planet. The satellites collect the sun's energy and contribute to the planet's energy production.",
        long_description:
          "Solar satellites are a crucial factor in supplying a planet with energy. Some empires rely entirely on the use of solar energy because it does not take up precious space on the planet. Of course, proximity to the sun is critical to this strategy. Since the satellites have no weapons and defense mechanisms, they must be supported with defense units.",
        type: :planet_ship,
        weapon_points: 0,
        shield_points: 1,
        hull_points: 200,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 202,
        name: "Crawler",
        list_order: 110,
        image_src: "/images/units/crawler.webp",
        short_description:
          "These units can only move on the surface of the planet. They contribute to the production of metal, crystal and deuterium on the planet. These units cannot be given fleet orders and cannot leave their planet.",
        long_description:
          "These units contribute significantly to the planet's metal, crystal, and deuterium production. The laser beams that support the ressource dismantling require a high level of energy, which the planet's infrastructure must first ensure. They are easy targets when attacked. Collectors move automatically on resource fields. They can therefore not be given any fleet orders.",
        type: :planet_ship,
        weapon_points: 0,
        shield_points: 1,
        hull_points: 5000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 301,
        name: "Espionage Probe",
        list_order: 120,
        image_src: "/images/units/espionage-probe.webp",
        short_description:
          "Spy probes are built to collect information about enemy planets. They are very small and enormously fast units.",
        long_description:
          "Spy probes are built to collect information about enemy planets. They are very small and enormously fast units.",
        type: :ship,
        weapon_points: 0,
        shield_points: 1,
        hull_points: 100,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 401,
        name: "Small Cargo Ship",
        list_order: 130,
        image_src: "/images/units/small-cargo.webp",
        short_description:
          "These small ships were designed purely for carrying raw materials, allowing quick allocation of resources between colonies. Their enormous maneuverability means that today they represent an elementary part of the goods traffic of every empire.",
        long_description:
          "With the expansion of the first colonies, there was an increasing need for fast deliveries of goods from the home planet. Mastering the less complex combustion engines was enough to build these versatile ships. Once the engineers develop the impulse engine at level 22, these ships will be equipped with the significantly faster impulse engine. With hyperspace engine at level 22, the speed of the ships can be significantly increased again! Attention: In the event of a combat mission, heavy losses are to be expected due to the low armor values.",
        type: :ship,
        weapon_points: 5,
        shield_points: 5,
        hull_points: 400,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 402,
        name: "Large Cargo Ship",
        list_order: 140,
        image_src: "/images/units/large-cargo.webp",
        short_description:
          "With around five times the cargo capacity of small transporters, large transporters offer an efficient way of loading huge amounts of resources efficiently. However, their disadvantage is that they are a bit slower than small transporters.",
        long_description:
          "As the demands for the rapid transfer of huge amounts of resources grew, it was time to find an alternative to the previous transporters. Through further research into the combustion engine, it was possible to significantly increase the size of the transporter. However, since the manoeuvrable transporters from the pre-series were still in high demand, the decision was made to use small and large transporters in separate areas of application. Once the engineers develop the impulse engine at level 22, these ships will be equipped with the impulse engine. With hyperspace engine at level 22, the speed of the ships can even more be significantly increased.",
        type: :ship,
        weapon_points: 10,
        shield_points: 15,
        hull_points: 1200,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 403,
        name: "Recycler",
        list_order: 150,
        image_src: "/images/units/large-cargo-v2.webp",
        short_description:
          "These ships can collect floating resources (known as debris fields) in space and bring them back to the Empire for re-use.",
        long_description:
          "Using a highly developed gill trap, these ships can filter raw materials floating in space. Due to the complicated technology and their large cargo space, recyclers are relatively slow. They are also not intended for combat use and therefore have little shield or weapon systems to speak of. With the development of the impulse engine at level 22, the ships will be equipped with this significantly faster engine. When researching hyperspace engine at level 22, an upgrade can be integrated again.",
        type: :ship,
        weapon_points: 5,
        shield_points: 10,
        hull_points: 1600,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 404,
        name: "Colony Ship",
        list_order: 160,
        image_src: "/images/units/colony.webp",
        short_description: "These ships are specially designed to colonize new planets.",
        long_description:
          "These ships are specially designed to colonize new planets. Even if they move slowly in space, it doesn't in the least diminish the settlers' joy in colonizing new planets. To not disappoint their hopes, but to make their new life as smooth as possible, colony ships will be loaded with resources far beyond their usual capacity limits when colonizing new planets.",
        type: :ship,
        weapon_points: 10,
        shield_points: 25,
        hull_points: 3000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 405,
        name: "Asteroid Miner",
        list_order: 170,
        image_src: "/images/units/asteroid-miner.webp",
        short_description:
          "Asteroid miners are ships specially designed to collect resources from asteroid surfaces.",
        long_description:
          "Asteroid miners are ships specially designed to collect resources from asteroid surfaces.",
        type: :ship,
        weapon_points: 20,
        shield_points: 200,
        hull_points: 6000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 501,
        name: "Rocket Launcher",
        list_order: 200,
        image_src: "/images/units/missile-launcher.webp",
        short_description:
          "Rocket launchers are a relic of the past, yet prove that in large numbers they are a cheap and effective defense mechanism.",
        long_description:
          "Rocket launchers are a relic of the past, yet prove that in large numbers they are a cheap and effective defense mechanism. The mechanism consists of simple ballistic projectiles, which can be fired by means of an ignition reaction.",
        type: :defense,
        weapon_points: 80,
        shield_points: 20,
        hull_points: 200,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 502,
        name: "Light Laser Turret",
        list_order: 210,
        image_src: "/images/units/light-laser.webp",
        short_description:
          "These underdeveloped turrets prove that simple technology can be devastating when multiple lasers combine their power. Due to their very low overall cost, many empires' defenses consist primarily of these turrets.",
        long_description:
          "Due to the energy fed in, atoms in the laser are shifted from lower energy levels to energetically higher (excited) states. By supplying a photon, the laser acts as a light amplifier, so excited atoms can be stimulated to emit in a chain reaction. These underdeveloped guns prove that simple technology can have devastating effects when multiple lasers combine their power. Due to their very low overall cost, many empires' defenses consist primarily of these guns.",
        type: :defense,
        weapon_points: 100,
        shield_points: 25,
        hull_points: 200,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 503,
        name: "Heavy Laser Turret",
        list_order: 220,
        image_src: "/images/units/heavy-laser.webp",
        short_description:
          "Through further research into laser technology, much larger guns with higher penetrating power could soon be built.",
        long_description:
          "Further research into laser technology soon made it possible to build significantly larger guns with greater penetrating power. A heavy laser cannon is around four times the size of a light laser cannon and offers around 2.5 times the firepower.",
        type: :defense,
        weapon_points: 250,
        shield_points: 100,
        hull_points: 800,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 504,
        name: "Ion Cannon",
        list_order: 230,
        image_src: "/images/units/ion-cannon.webp",
        short_description:
          "Ion cannons accelerate small particles to such high speeds that they damage the attacking fleet's electronics and navigational equipment.",
        long_description:
          "Ion cannons accelerate small particles to such high speeds that they damage the attacking fleet's electronics and navigational equipment. Since the deployed ions can also be used as shields by reversing their direction, the shield values of these units are very high.",
        type: :defense,
        weapon_points: 150,
        shield_points: 500,
        hull_points: 800,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 505,
        name: "Gauss Cannon",
        list_order: 240,
        image_src: "/images/units/gauss-cannon.webp",
        short_description:
          "The penetrating power of the huge projectiles in this gun can be further increased by ferromagnetic acceleration.",
        long_description:
          "The penetrating power of the huge projectiles could be increased again by ferromagnetic acceleration. Their drive essentially consists of magnetism, just as it is used in the force fields of magnetic levitation. The naming is based on the German physicist Carl Gauss and his discovered unit of magnetic flux density named after him.",
        type: :defense,
        weapon_points: 1100,
        shield_points: 200,
        hull_points: 3500,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 506,
        name: "Plasma Cannon",
        list_order: 250,
        image_src: "/images/units/plasma-cannon.webp",
        short_description:
          "When it hits enemy weapons and navigation systems, the electrical conductivity of plasma will bypass circuits for truly devastating damage regarding maneuverability.",
        long_description:
          "Plasma has a truly destructive power due to its ability to store large amounts of energy. In combination with laser and ion technology, the plasma could be stabilized for the first time and thus fired at targets using high-kinetic launchers. When it hits enemy weapons and navigation systems, the electrical conductivity of plasma will bypass circuits for truly devastating damage regarding maneuverability. A failure of the electrical systems renders enemy ships completely unusable and steers around in space as unmaneuverable space debris.",
        type: :defense,
        weapon_points: 3000,
        shield_points: 300,
        hull_points: 10_000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 507,
        name: "Small Shield Dome",
        list_order: 260,
        image_src: "/images/units/small-shield.webp",
        short_description:
          "The small shield dome covers the defense units and ships with a protective energy shield using a generator. This can absorb additional energy from the outside and is still permeable enough to let your own defenses fire.",
        long_description:
          "The small shield dome covers facilities and units with a protective energy shield using a generator. This can absorb additional energy from the outside and is still permeable enough to let own defense systems fire. Due to the high energy voltage required, only a limited number of shield domes can be built per planet. This amount can be increased by the ongoing progress of the empire.",
        type: :defense,
        weapon_points: 0,
        shield_points: 2000,
        hull_points: 4000,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 508,
        name: "Large Shield Dome",
        list_order: 270,
        image_src: "/images/units/large-shield.webp",
        short_description:
          "Further research into shield technologies has significantly improved the resilience of small shield domes. Large shield domes thus cover a much larger area of the planet, which means that its facilities and units can be protected much more efficiently.",
        long_description:
          "Further research into shield technologies has significantly improved the resilience of small shield domes. Large shield domes thus cover a much larger area of the planet, which means that more facilities and units can be protected more efficiently. Due to the high energy voltage required, only a limited number of shield domes can be built per planet. That number can be increased by ongoing progress of the empire.",
        type: :defense,
        weapon_points: 0,
        shield_points: 10_000,
        hull_points: 20_000,
        inserted_at: now,
        updated_at: now
      },
      # %{
      #   id: 509,
      #   name: "Fortress",
      #   image_src: "/images/units/.webp",
      #   short_description:
      #     "These massive defense rings are built around the planet's buildings and facilities. Due to their high durability, they drastically reduce the effectiveness of enemy attacks.",
      #   long_description:
      #     "These massive defense rings are built around the planet's buildings and facilities. Due to their high durability, they drastically reduce the effectiveness of enemy attacks. The construction of the complex is reminiscent of long-forgotten civilizations, that tried to protect their cities from invaders with stone walls. Of course, the materials used are not in the least comparable. In addition to protecting the infrastructure, the highly developed weapon systems can simultaneously defend entire cities by opening fire on the attacker at the same time. With every unit the thickness of fortress is being increased.",
      #   type: :defense,
      #   weapon_points: 10_800,
      #   shield_points: 20_000,
      #   hull_points: 960_000
      # },
      # %{
      #   id: 510,
      #   name: "Doom Cannon",
      #   image_src: "/images/units/.webp",
      #   short_description:
      #     "The doom cannon's massive blasts of energy can even hit multiple Death Stars and Avatars at once with their unimaginable level of destructive power.",
      #   long_description:
      #     "During the first test attempts by scientists, there was a short-term power failure when the cannons were used. Due to the total darkness combined with the rumbling sound, the inhabitants thought the planet was about to collapse. Since then, the huge cannons have been called \"Cannons of Doom\". Inside these cannons, graviton and plasma articles are first fused in a nuclear fusion. However, the unstable mixture implodes after a short time, so that the outer shells only have the purpose of directing the projectile in the approximate direction of the attacker. The enormous bursts of energy from the plasma-graviton-cannon can even hit several Death Stars and Avatars at once due to their unimaginable degree of destructive power.",
      #   type: :defense,
      #   weapon_points: 20_000,
      #   shield_points: 120_000,
      #   hull_points: 3_600_000
      # },
      # %{
      #   id: 511,
      #   name: "Orbital Defense Platform",
      #   image_src: "/images/units/.webp",
      #   short_description:
      #     "This massive defense system is integrated into the planet's orbit. Simultaneously firing at devastating proportions, she can destroy entire enemy fleets in one salvo.",
      #   long_description:
      #     "Due to the technological advancement of warships there was much need for a new defence system to counter massive enemy fleets. This massive defense system is integrated into the planet's orbit. Simultaneously firing at devastating proportions, she can destroy entire enemy fleets in one salvo.",
      #   type: :defense,
      #   weapon_points: 96_000,
      #   shield_points: 1_000_000,
      #   hull_points: 22_400_000
      # },
      # %{
      #   id: 512,
      #   name: "Atmospheric Shield",
      #   image_src: "/images/units/.webp",
      #   short_description:
      #     "These vast energy shields reinforce a planet's natural atmosphere. They span the entire planet and, in conjunction with other defense systems, make it possible to withstand even major attacks without damage.",
      #   long_description:
      #     "These vast energy shields reinforce a planet's natural atmosphere. They span the entire planet and, in conjunction with other defense systems, make it possible to withstand even major attacks without damage. Due to the high energy voltage required, only a limited number of atmospheric shields can be built per planet.",
      #   type: :defense,
      #   weapon_points: 0,
      #   shield_points: 2_000_000,
      #   hull_points: 4_000_000
      # },
      %{
        id: 601,
        name: "Interceptor Missile",
        list_order: 280,
        image_src: "/images/units/interceptor-missile.webp",
        short_description:
          "With this anti-ballistic missile defense system, incoming interplanetary missiles can be successfully shot down in the stratosphere.",
        long_description: "TBD",
        type: :missile,
        weapon_points: 0,
        shield_points: 0,
        hull_points: 6500,
        inserted_at: now,
        updated_at: now
      },
      %{
        id: 602,
        name: "Interplanetary Missile",
        list_order: 290,
        image_src: "/images/units/interplanetary-missile.webp",
        short_description:
          "The plasma warheads used by the interplanetary missiles cause devastating damage to enemy defense systems - if they are not protected by interceptor missiles. Defenses destroyed by missiles are not restored.",
        long_description:
          "Interplanetary missiles represent the further development of long-distance missiles already known from the 20th century. However, escaping the atmosphere of a planet without triggering the sensitive explosive device posed a challenge for the developers for a long time. By exploiting robotic and nanite technology, the interplanetary missiles can now be mass-produced. The main costs are related to the filling of the huge deuterium tanks, which are required for the launch of the missiles. The detonating plasma warheads lead to devastating damage to enemy defense systems - if they are not protected by interceptor missiles. Defenses destroyed by missiles are not restored.",
        type: :missile,
        weapon_points: 15_000,
        shield_points: 0,
        hull_points: 12_500,
        inserted_at: now,
        updated_at: now
      }
    ])
  end
end
