defmodule Galaxies.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Galaxies.Repo

  alias Galaxies.Accounts.{Player, PlayerToken, PlayerNotifier}
  alias Galaxies.{Building, PlanetBuilding}

  require Logger

  @resource_buildings [
    "Metal Mine",
    "Crystal Mine",
    "Deuterium Refinery",
    "Solar Power Plant",
    "Fusion Reactor",
    "Metal Storage",
    "Crystal Storage",
    "Deuterium Tank"
  ]

  @facility_buildings [
    "Robot Factory",
    "Nanite Factory",
    "Shipyard",
    "Research Lab",
    "Terraformer",
    "Missile Silo"
  ]

  ## Database getters

  @doc """
  Gets a player by email.

  ## Examples

      iex> get_player_by_email("foo@example.com")
      %Player{}

      iex> get_player_by_email("unknown@example.com")
      nil

  """
  def get_player_by_email(email) when is_binary(email) do
    Repo.get_by(Player, email: email)
  end

  @doc """
  Gets a player by email and password.

  ## Examples

      iex> get_player_by_email_and_password("foo@example.com", "correct_password")
      %Player{}

      iex> get_player_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_player_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    player = Repo.get_by(Player, email: email)
    if Player.valid_password?(player, password), do: player
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  ## Player registration

  @doc """
  Registers a player and creates a planet for that player.

  ## Examples

      iex> register_player(%{field: value})
      {:ok, %{player: %Player{}, planet: %Planet{}}}

      iex> register_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_player(attrs) do
    home_planet_id = Ecto.UUID.generate()

    attrs =
      Enum.reduce(attrs, %{}, fn
        {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
        {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
      end)

    player_changeset =
      Player.registration_changeset(
        %Player{},
        Map.put(attrs, :current_planet_id, home_planet_id)
      )

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:player, player_changeset)
    |> Ecto.Multi.insert(:planet, fn %{player: player} ->
      {galaxy, system, slot} = get_available_planet_slot()

      player
      |> Ecto.build_assoc(:planets, %{
        id: home_planet_id,
        name: "Home World",
        galaxy: galaxy,
        system: system,
        slot: slot,
        min_temperature: -40,
        max_temperature: 40,
        image_id: 1
      })
    end)
    |> Ecto.Multi.run(:planet_buildings, fn repo, %{player: player, planet: planet} ->
      now = DateTime.utc_now()

      planet_buildings =
        repo.all(from(b in Building))
        |> Enum.map(fn building ->
          %{
            planet_id: planet.id,
            building_id: building.id,
            current_level: 0,
            inserted_at: now,
            updated_at: now
          }
        end)

      {building_count, nil} = repo.insert_all(PlanetBuilding, planet_buildings)

      Logger.debug(
        "inserted #{building_count} planet_buildings for planet #{planet.name} of #{player.username}"
      )

      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, results} -> {:ok, results}
      {:error, :player, changeset, _} -> {:error, changeset}
    end
  end

  defp get_available_planet_slot(),
    do: {Enum.random(1..17), Enum.random(1..999), Enum.random(4..12)}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player_registration(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player_registration(%Player{} = player, attrs \\ %{}) do
    Player.registration_changeset(player, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the player email.

  ## Examples

      iex> change_player_email(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player_email(player, attrs \\ %{}) do
    Player.email_changeset(player, attrs, validate_email: false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the player username.

  ## Examples

      iex> change_player_username(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player_username(player, attrs \\ %{}) do
    Player.username_changeset(player, attrs, validate_username: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_player_email(player, "valid password", %{email: ...})
      {:ok, %Player{}}

      iex> apply_player_email(player, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_player_email(player, password, attrs) do
    player
    |> Player.email_changeset(attrs)
    |> Player.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the player email using the given token.

  If the token matches, the player email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_player_email(player, token) do
    context = "change:#{player.email}"

    with {:ok, query} <- PlayerToken.verify_change_email_token_query(token, context),
         %PlayerToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(player_email_multi(player, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp player_email_multi(player, email, context) do
    changeset =
      player
      |> Player.email_changeset(%{email: email})
      |> Player.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:player, changeset)
    |> Ecto.Multi.delete_all(:tokens, PlayerToken.by_player_and_contexts_query(player, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given player.

  ## Examples

      iex> deliver_player_update_email_instructions(player, current_email, &url(~p"/players/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_player_update_email_instructions(
        %Player{} = player,
        current_email,
        update_email_url_fun
      )
      when is_function(update_email_url_fun, 1) do
    {encoded_token, player_token} =
      PlayerToken.build_email_token(player, "change:#{current_email}")

    Repo.insert!(player_token)
    PlayerNotifier.deliver_update_email_instructions(player, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the player password.

  ## Examples

      iex> change_player_password(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player_password(player, attrs \\ %{}) do
    Player.password_changeset(player, attrs, hash_password: false)
  end

  @doc """
  Updates the player password.

  ## Examples

      iex> update_player_password(player, "valid password", %{password: ...})
      {:ok, %Player{}}

      iex> update_player_password(player, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_player_password(player, password, attrs) do
    changeset =
      player
      |> Player.password_changeset(attrs)
      |> Player.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:player, changeset)
    |> Ecto.Multi.delete_all(:tokens, PlayerToken.by_player_and_contexts_query(player, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{player: player}} -> {:ok, player}
      {:error, :player, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Emulates that the username will change without actually changing
  it in the database.

  ## Examples

      iex> apply_player_username(player, "valid password", %{username: ...})
      {:ok, %Player{}}

      iex> apply_player_username(player, "invalid password", %{username: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_player_username(player, password, attrs) do
    changeset =
      player
      |> Player.username_changeset(attrs)
      |> Player.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:player, changeset)
    |> Ecto.Multi.delete_all(:tokens, PlayerToken.by_player_and_contexts_query(player, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{player: player}} -> {:ok, player}
      {:error, :player, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_player_session_token(player) do
    {token, player_token} = PlayerToken.build_session_token(player)
    Repo.insert!(player_token)
    token
  end

  @doc """
  Gets the player with the given signed token.
  """
  def get_player_by_session_token(token) do
    {:ok, query} = PlayerToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the current active planet for a given player.
  """
  def get_active_planet(player) do
    {:ok, query} = Player.get_active_planet_query(player)
    Repo.one(query)
  end

  @doc """
  Gets the resource buildings for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_resource_buildings(planet) do
    query =
      from building in Building,
        where: building.name in @resource_buildings,
        join: planet_building in PlanetBuilding,
        on: building.id == planet_building.building_id,
        where: planet_building.planet_id == ^planet.id,
        select: %{
          id: building.id,
          name: building.name,
          description_short: building.short_description,
          description_long: building.long_description,
          image_src: building.image_src,
          current_level: planet_building.current_level,
          upgrade_cost_formula: building.upgrade_cost_formula
        }

    Repo.all(query)
  end

  @doc """
  Gets the facilities buildings for a specific planet.
  """
  def get_planet_facilities_buildings(planet) do
    query =
      from building in Building,
        where: building.name in @facility_buildings,
        join: planet_building in PlanetBuilding,
        on: building.id == planet_building.building_id,
        where: planet_building.planet_id == ^planet.id,
        select: %{
          id: building.id,
          name: building.name,
          description_short: building.short_description,
          description_long: building.long_description,
          image_src: building.image_src,
          current_level: planet_building.current_level,
          upgrade_cost_formula: building.upgrade_cost_formula
        }

    Repo.all(query)
  end

  @doc """
  Gets the research for a specific player.
  Currently returning a stubbed response.
  """
  def get_player_researches(_player) do
    [
      %{
        name: "Spy Technology",
        image_src: "/images/researches/espionage.webp",
        description_short:
          "As the level of this technique increases, more detailed information can be obtained from spying missions, while enemy spy probes can collect less information from your planets.",
        description_long:
          "Espionage Technology is, in the first instance, an advancement of sensor technology. The more advanced this technology is, the more information the user receives about activities in his environment. The differences between your own spy level and opposing spy levels is crucial for probes. The more advanced your own espionage technology is, the more information the report can gather and the smaller the chance is that your espionage activities are discovered. The more probes that you send on one mission, the more details they can gather from the target planet. But at the same time it also increases the chance of discovery."
      },
      %{
        name: "Computer Technology",
        image_src: "/images/researches/computer.webp",
        description_short: "Increases the maximum fleet slot by 1.",
        description_long:
          "Once launched on any mission, fleets are controlled primarily by a series of computers located on the originating planet. These massive computers calculate the exact time of arrival, controls course corrections as needed, calculates trajectories, and regulates flight speeds. With each level researched, the flight computer is upgraded to allow an additional slot to be launched. Computer technology should be continuously developed throughout the building of your empire."
      },
      %{
        name: "Energy Technology",
        image_src: "/images/researches/energy.webp",
        description_short: "Increases energy production by 2%.",
        description_long:
          "As various fields of research advanced, it was discovered that the current technology of energy distribution was not sufficient enough to begin certain specialized research. With each upgrade of your Energy Technology, new research can be conducted which unlocks development of more sophisticated ships and defences."
      },
      %{
        name: "Laser Technology",
        image_src: "/images/researches/laser.webp",
        description_short: "Increases the attack power of laser weapons by 1%.",
        description_long:
          "Lasers (light amplification by stimulated emission of radiation) produce an intense, energy rich emission of coherent light. These devices can be used in all sorts of areas, from optical computers to heavy laser weapons, which effortlessly cut through armour technology. The laser technology provides an important basis for research of other weapon technologies."
      },
      %{
        name: "Ion Technology",
        image_src: "/images/researches/ion.webp",
        description_short: "Increases the attack power of ion weapons by 1%.",
        description_long:
          "Ions can be concentrated and accelerated into a deadly beam. These beams can then inflict enormous damage. Our scientists have also developed a technique that will clearly reduce the deconstruction costs for buildings and systems."
      },
      %{
        name: "Plasma Technology",
        image_src: "/images/researches/plasma.webp",
        description_short: "Increases the attack power of plasma weapons by 1%.",
        description_long:
          "A further development of ion technology that doesn`t speed up ions but high-energy plasma instead, which can then inflict devastating damage on impact with an object."
      },
      %{
        name: "Graviton Technology",
        image_src: "/images/researches/graviton.webp",
        description_short: "Increases the attack power of graviton weapons by 2%.",
        description_long:
          "A graviton is an elementary particle that is massless and has no cargo. It determines the gravitational power. By firing a concentrated load of gravitons, an artificial gravitational field can be constructed. Not unlike a black hole, it draws mass into itself. Thus it can destroy ships and even entire moons. To produce a sufficient amount of gravitons, huge amounts of energy are required. Graviton Research is required to construct a destructive Deathstar."
      },
      %{
        name: "Weapons Technology",
        image_src: "/images/researches/weapons.webp",
        description_short: "Increases the attack power of all units by 10%.",
        description_long:
          "Weapons Technology is a key research technology and is critical to your survival against enemy Empires. With each level of Weapons Technology researched, the weapons systems on ships and your defence mechanisms become increasingly more efficient. Each level increases the base strength of your weapons by 10% of the base value."
      },
      %{
        name: "Shields Technology",
        image_src: "/images/researches/shield.webp",
        description_short: "Increases the shield power of all units by 10%.",
        description_long:
          "With the invention of the magnetosphere generator, scientists learned that an artificial shield could be produced to protect the crew in space ships not only from the harsh solar radiation environment in deep space, but also provide protection from enemy fire during an attack. Once scientists finally perfected the technology, a magnetosphere generator was installed on all ships and defence systems. As the technology is advanced to each level, the magnetosphere generator is upgraded which provides an additional 10% strength to the shields base value."
      },
      %{
        name: "Armor Technology",
        image_src: "/images/researches/armor.webp",
        description_short: "Increases the armor power of all units by 10%.",
        description_long:
          "The environment of deep space is harsh. Pilots and crew on various missions not only faced intense solar radiation, they also faced the prospect of being hit by space debris, or destroyed by enemy fire in an attack. With the discovery of an aluminum-lithium titanium carbide alloy, which was found to be both light weight and durable, this afforded the crew a certain degree of protection. With each level of Armour Technology developed, a higher quality alloy is produced, which increases the armours strength by 10%."
      },
      %{
        name: "Hyperspace Technology",
        image_src: "/images/researches/hyperspace.webp",
        description_short:
          "Hyperspace technology increases expedition and asteroid mining gains by 1%.",
        description_long:
          "In theory, the idea of hyperspace travel relies on the existence of a separate and adjacent dimension. When activated, a hyperspace drive shunts the starship into this other dimension, where it can cover vast distances in an amount of time greatly reduced from the time it would take in \"normal\" space. Once it reaches the point in hyperspace that corresponds to its destination in real space, it re-emerges."
      },
      %{
        name: "Combustion Engine Technology",
        image_src: "/images/researches/combustion.webp",
        description_short: "Increases the speed of all ships using a combustion engine by 10%.",
        description_long:
          "The Combustion Drive is the oldest of technologies, but is still in use. With the Combustion Drive, exhaust is formed from propellants carried within the ship prior to use. In a closed chamber, the pressures are equal in each direction and no acceleration occurs. If an opening is provided at the bottom of the chamber then the pressure is no longer opposed on that side. The remaining pressure gives a resultant thrust in the side opposite the opening, which propels the ship forward by expelling the exhaust rearwards at extreme high speed."
      },
      %{
        name: "Impulse Engine Technology",
        image_src: "/images/researches/impulse.webp",
        description_short: "Increases the speed of all ships using a impulse engine by 20%.",
        description_long:
          "The impulse drive is based on the recoil principle, by which the stimulated emission of radiation is mainly produced as a waste product from the core fusion to gain energy."
      },
      %{
        name: "Hyperspace Engine Technology",
        image_src: "/images/researches/warp.webp",
        description_short: "Increases the speed of all ships using a hyperspace engine by 30%.",
        description_long:
          "Long distances can be covered very quickly due to the curvature of the immediate vicinity of the ship. The more developed the hyperspace propellant, the greater the curvature of space."
      },
      %{
        name: "Cargo Technology",
        image_src: "/images/researches/cargo.webp",
        description_short:
          "Increases the cargo capacity of Cargo ships by 50% and increases the cargo capacity of all other ships by 5%.",
        description_long:
          "As the empire's need for resources grows, shipping costs increase at the same rate. Scientists have been working on reducing resource costs for many years, and eventually they were able to make cargo technology what it is today. Each level of this technology greatly increases the carrying capacity of cargo ships, while increasing the shipping capacity of all other ships."
      },
      %{
        name: "Astrophysics Technology",
        image_src: "/images/researches/astrophysics.webp",
        description_short:
          "This technology allows you to colonize new planets and increase the maximum number of expedition missions.",
        description_long:
          "Further findings in the field of astrophysics allow for the construction of laboratories that can be fitted on more and more ships. This makes long expeditions far into unexplored areas of space possible. In addition these advancements can be used to further colonise the universe. For every two levels of this technology an additional planet can be made usable."
      },
      %{
        name: "Intergalactic Research Network",
        image_src: "/images/researches/intergalactic-research-network.webp",
        description_short:
          "Scientific research laboratories on different planets connect to each other and increasing the speed of research.",
        description_long:
          "When research is getting more and more complex scientists are revolutionary to connect individual laboratories developed a path: Intergalactic Research Network! Central computers of research stations via this network they connect directly with each other, which speeds up research. A research laboratory is connected for each level researched. Always here laboratories with the highest level are added. The networked lab is should be developed sufficiently to carry out independently. All participating laboratories expansion stages meet in intergalactic research network was introduced."
        # },
        # %{
        #   name: "Mineral Extration Technology",
        #   image_src: "/images/researches/.webp",
        #   description_short: "Increases metal mine production on all planets.",
        #   description_long:
        #     "Since metal is the most widely used resource in the industry, efforts have been made to increase production power. As a result of using the raw resources processed in metal mines more effectively, metal production power also increases considerably."
        # },
        # %{
        #   name: "Crystallization Technology",
        #   image_src: "/images/researches/.webp",
        #   description_short: "Increases crystal mine production on all planets.",
        #   description_long:
        #     "Since crystals are frangible, processing and using them require great skill. As the industry's need for crystals increases, efforts are being made to avoid wasting crystals."
        # },
        # %{
        #   name: "Fuel Cell Technology",
        #   image_src: "/images/researches/.webp",
        #   description_short: "Increases deuterium production on all planets.",
        #   description_long:
        #     "Since Deuterium deposits are mostly under the sea, removing and storing them requires great efforts. Some of the deuterium may become unusable during this process. Scientists are working to use these resources more effectively in many fields. The amount of raw deuterium required decreases as fuel technology improves."
      }
    ]
  end

  @doc """
  Gets the ship units for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_ship_units(_planet) do
    [
      %{
        name: "Light Fighter",
        image_src: "/images/units/light-fighter.webp",
        description_short:
          "They are the most primitive warships of an empire. But when their number increases, they can easily destroy even huge ships.",
        description_long:
          "Light fighters are the most primitive warships of an empire. In large numbers, however, they manage to successfully confront even fleets composed of larger ships. Their low cost allows empires to create gigantic amounts of light fighters.",
        type: "ship",
        attack_value: 50,
        shield_value: 10,
        hit_points: 400
      },
      %{
        name: "Heavy Fighter",
        image_src: "/images/units/heavy-fighter.webp",
        description_short:
          "The constant further development of the light fighters finally made the production of the much more stable heavy fighters possible.",
        description_long:
          "The constant further development of the light fighters finally made it possible to produce significantly more stable ships. Due to the high proportion of crystals in development and a significant increase in fuel consumption, there are many empires that still cling to light fighters.",
        type: "ship",
        attack_value: 150,
        shield_value: 25,
        hit_points: 1000
      },
      %{
        name: "Cruiser",
        image_src: "/images/units/cruiser.webp",
        description_short:
          "Due to their maneuverability and high speed, cruisers are a major challenge for enemy fleets and defenses.",
        description_long:
          "With further research into impulse engines, it was possible to far surpass the speed of the light and heavy fighters. It was time to declare war on the dominant fleets of fighters. Cruisers were therefore equipped with special ion cannons that could target multiple light fighters at the same time. Even in highly developed civilizations, cruisers are often used ships due to their maneuverability and high speed. They continue to pose a major challenge to enemy fighter fleets.",
        type: "ship",
        attack_value: 400,
        shield_value: 50,
        hit_points: 2700
      },
      %{
        name: "Battleship",
        image_src: "/images/units/battleship.webp",
        description_short:
          "Battleships are the backbone for early fleets, providing a high resistance to ships designed to overpower defenses during the first stages of new empires.",
        description_long:
          "Battleships are the backbone for early fleets, providing a high resistance to ships designed to overpower defenses during the first stages of new empires. Battleships have ample storage capacity making them the preferred choice for bringing back raw materials that have been plundered.",
        type: "ship",
        attack_value: 1000,
        shield_value: 200,
        hit_points: 6000
      },
      %{
        name: "Interceptor",
        image_src: "/images/units/interceptor.webp",
        description_short:
          "Interceptors are very agile ships with sophisticated weapon systems. They were designed to counterbalance the prevailing battleships.",
        description_long:
          "Battlecruisers are very agile ships with sophisticated weapon systems. They were designed to counterbalance the prevailing battleships. However, their cargo space and fuel consumption are significantly smaller due to the revised design.",
        type: "ship",
        attack_value: 700,
        shield_value: 400,
        hit_points: 7000
      },
      %{
        name: "Bomber",
        image_src: "/images/units/bombardier.webp",
        description_short:
          "Bombers are designed to destroy the enemy's defense line. Their concentrated bombardments are very strong against defensive units.",
        description_long:
          "It could be observed that some empires bunkered huge deposits of resources behind their defenses. Thanks to specialized plasma bombardments, even previously impregnable strongholds could be knocked out with almost no casualties. However, the heavy combat systems made the bomber very slow at the same time. Its weapon systems are designed to destroy geostationary guns, so that fights against other warships are mostly hopeless.",
        type: "ship",
        attack_value: 1000,
        shield_value: 500,
        hit_points: 7500
      },
      %{
        name: "Destroyer",
        image_src: "/images/units/dreadnaught.webp",
        description_short:
          "Destroyers are the most fearful of middle class warships due to their high shield strength and damage ability.",
        description_long:
          "Further exploration of hyperspace allowed empires to integrate entire arsenals into spaceships. These flying battle bases can only be stopped effectively by significantly larger ships. Due to their sheer size, the fuel consumption is double that of battleships. Due to the large number of weapon systems, the effective cargo hold has become even smaller at the same time. Destroyers are the most dangerous mid-tier warships due to their high shield strength and damage ability.",
        type: "ship",
        attack_value: 2000,
        shield_value: 500,
        hit_points: 11_000
      },
      %{
        name: "Reaper",
        image_src: "/images/units/battleship-v3.webp",
        description_short:
          "The ability to collect debris fields immediately after battle has made this warship one of the most popular in the universe! They can directly collect a maximum of 40% of the total debris.",
        description_long:
          "The constant further development of the destroyers represented a change in the previous warfare. Reapers were not only clearly superior to previous ships in terms of their combat values. The integration of recycler technology also made it possible, to fill the generously dimensioned cargo hold directly after the battle with debris fields that had been created (up to 40% for own attacks / up to 100% for expedition-fights). Of course, this technology led to a sustained increase in numbers of these ships.",
        type: "ship",
        attack_value: 2800,
        shield_value: 700,
        hit_points: 14_000
      },
      %{
        name: "Deathstar",
        image_src: "/images/units/juggernaut.webp",
        description_short:
          "The destructive power of Death Stars is unmatched. By focusing huge amounts of energy, the gigantic gravitational cannon can even destroy entire moons.",
        description_long:
          "The destructive power of Death Stars is unmatched. By focusing huge amounts of energy, the gigantic gravitational cannon can even destroy entire moons. However, there are rumors of imploding Death Stars, which can be traced back to overstressing the gravity cannon on moons that are too large. It's up to every empires leader to use this technology wisely. Their sheer size also makes the Death Stars very slow.",
        type: "ship",
        attack_value: 12_000,
        shield_value: 16_000,
        hit_points: 900_000
      },
      %{
        name: "Solar Satellite",
        image_src: "/images/units/solar-satellite.webp",
        description_short:
          "Solar satellites are launched directly into the orbit of the respective planet. The satellites collect the sun's energy and contribute to the planet's energy production.",
        description_long:
          "Solar satellites are a crucial factor in supplying a planet with energy. Some empires rely entirely on the use of solar energy because it does not take up precious space on the planet. Of course, proximity to the sun is critical to this strategy. Since the satellites have no weapons and defense mechanisms, they must be supported with defense units.",
        type: "planet_ship",
        attack_value: 0,
        shield_value: 1,
        hit_points: 200
      },
      %{
        name: "Crawler",
        image_src: "/images/units/crawler.webp",
        description_short:
          "These units can only move on the surface of the planet. They contribute to the production of metal, crystal and deuterium on the planet. These units cannot be given fleet orders and cannot leave their planet.",
        description_long:
          "These units contribute significantly to the planet's metal, crystal, and deuterium production. The laser beams that support the ressource dismantling require a high level of energy, which the planet's infrastructure must first ensure. They are easy targets when attacked. Collectors move automatically on resource fields. They can therefore not be given any fleet orders.",
        type: "planet_ship",
        attack_value: 0,
        shield_value: 1,
        hit_points: 5000
      },
      %{
        name: "Spy Probe",
        image_src: "/images/units/espionage-probe.webp",
        description_short:
          "Spy probes are built to collect information about enemy planets. They are very small and enormously fast units.",
        description_long:
          "Spy probes are built to collect information about enemy planets. They are very small and enormously fast units.",
        type: "ship",
        attack_value: 0,
        shield_value: 1,
        hit_points: 100
      },
      %{
        name: "Small Cargo Ship",
        image_src: "/images/units/light-cargo.webp",
        description_short:
          "These small ships were designed purely for carrying raw materials, allowing quick allocation of resources between colonies. Their enormous maneuverability means that today they represent an elementary part of the goods traffic of every empire.",
        description_long:
          "With the expansion of the first colonies, there was an increasing need for fast deliveries of goods from the home planet. Mastering the less complex combustion engines was enough to build these versatile ships. Once the engineers develop the impulse engine at level 22, these ships will be equipped with the significantly faster impulse engine. With hyperspace engine at level 22, the speed of the ships can be significantly increased again! Attention: In the event of a combat mission, heavy losses are to be expected due to the low armor values.",
        type: "ship",
        attack_value: 5,
        shield_value: 5,
        hit_points: 400
      },
      %{
        name: "Large Cargo Ship",
        image_src: "/images/units/large-cargo.webp",
        description_short:
          "With around five times the cargo capacity of small transporters, large transporters offer an efficient way of loading huge amounts of resources efficiently. However, their disadvantage is that they are a bit slower than small transporters.",
        description_long:
          "As the demands for the rapid transfer of huge amounts of resources grew, it was time to find an alternative to the previous transporters. Through further research into the combustion engine, it was possible to significantly increase the size of the transporter. However, since the manoeuvrable transporters from the pre-series were still in high demand, the decision was made to use small and large transporters in separate areas of application. Once the engineers develop the impulse engine at level 22, these ships will be equipped with the impulse engine. With hyperspace engine at level 22, the speed of the ships can even more be significantly increased.",
        type: "ship",
        attack_value: 10,
        shield_value: 15,
        hit_points: 1200
      },
      %{
        name: "Recycler",
        image_src: "/images/units/large-cargo-v2.webp",
        description_short:
          "These ships can collect floating resources (known as debris fields) in space and bring them back to the Empire for re-use.",
        description_long:
          "Using a highly developed gill trap, these ships can filter raw materials floating in space. Due to the complicated technology and their large cargo space, recyclers are relatively slow. They are also not intended for combat use and therefore have little shield or weapon systems to speak of. With the development of the impulse engine at level 22, the ships will be equipped with this significantly faster engine. When researching hyperspace engine at level 22, an upgrade can be integrated again.",
        type: "ship",
        attack_value: 5,
        shield_value: 10,
        hit_points: 1600
      },
      %{
        name: "Colonizer",
        image_src: "/images/units/colony.webp",
        description_short: "These ships are specially designed to colonize new planets.",
        description_long:
          "These ships are specially designed to colonize new planets. Even if they move slowly in space, it doesn't in the least diminish the settlers' joy in colonizing new planets. To not disappoint their hopes, but to make their new life as smooth as possible, colony ships will be loaded with resources far beyond their usual capacity limits when colonizing new planets.",
        type: "ship",
        attack_value: 10,
        shield_value: 25,
        hit_points: 3000
      },
      %{
        name: "Asteroid Miner",
        image_src: "/images/units/asteroid-miner.webp",
        description_short:
          "Asteroid miners are ships specially designed to collect resources from asteroid surfaces.",
        description_long:
          "Asteroid miners are ships specially designed to collect resources from asteroid surfaces.",
        type: "ship",
        attack_value: 20,
        shield_value: 200,
        hit_points: 6000
      }
    ]
  end

  @doc """
  Gets the defense units for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_defense_units(_planet) do
    [
      %{
        name: "Missile Launcher",
        image_src: "/images/units/missile-launcher.webp",
        description_short:
          "Rocket launchers are a relic of the past, yet prove that in large numbers they are a cheap and effective defense mechanism.",
        description_long:
          "Rocket launchers are a relic of the past, yet prove that in large numbers they are a cheap and effective defense mechanism. The mechanism consists of simple ballistic projectiles, which can be fired by means of an ignition reaction.",
        type: "defense",
        attack_value: 80,
        shield_value: 20,
        hit_points: 200
      },
      %{
        name: "Light Laser Turret",
        image_src: "/images/units/light-laser-turret.webp",
        description_short:
          "These underdeveloped turrets prove that simple technology can be devastating when multiple lasers combine their power. Due to their very low overall cost, many empires' defenses consist primarily of these turrets.",
        description_long:
          "Due to the energy fed in, atoms in the laser are shifted from lower energy levels to energetically higher (excited) states. By supplying a photon, the laser acts as a light amplifier, so excited atoms can be stimulated to emit in a chain reaction. These underdeveloped guns prove that simple technology can have devastating effects when multiple lasers combine their power. Due to their very low overall cost, many empires' defenses consist primarily of these guns.",
        type: "defense",
        attack_value: 100,
        shield_value: 25,
        hit_points: 200
      },
      %{
        name: "Heavy Laser Turret",
        image_src: "/images/units/heavy-laser-turret.webp",
        description_short:
          "Through further research into laser technology, much larger guns with higher penetrating power could soon be built.",
        description_long:
          "Further research into laser technology soon made it possible to build significantly larger guns with greater penetrating power. A heavy laser cannon is around four times the size of a light laser cannon and offers around 2.5 times the firepower.",
        type: "defense",
        attack_value: 250,
        shield_value: 100,
        hit_points: 800
      },
      %{
        name: "Ion Cannon",
        image_src: "/images/units/ion-cannon.webp",
        description_short:
          "Ion cannons accelerate small particles to such high speeds that they damage the attacking fleet's electronics and navigational equipment.",
        description_long:
          "Ion cannons accelerate small particles to such high speeds that they damage the attacking fleet's electronics and navigational equipment. Since the deployed ions can also be used as shields by reversing their direction, the shield values of these units are very high.",
        type: "defense",
        attack_value: 150,
        shield_value: 500,
        hit_points: 800
      },
      %{
        name: "Gauss Cannon",
        image_src: "/images/units/gauss-cannon.webp",
        description_short:
          "The penetrating power of the huge projectiles in this gun can be further increased by ferromagnetic acceleration.",
        description_long:
          "The penetrating power of the huge projectiles could be increased again by ferromagnetic acceleration. Their drive essentially consists of magnetism, just as it is used in the force fields of magnetic levitation. The naming is based on the German physicist Carl Gauss and his discovered unit of magnetic flux density named after him.",
        type: "defense",
        attack_value: 1100,
        shield_value: 200,
        hit_points: 3500
      },
      %{
        name: "Plasma Cannon",
        image_src: "/images/units/plasma-cannon.webp",
        description_short:
          "When it hits enemy weapons and navigation systems, the electrical conductivity of plasma will bypass circuits for truly devastating damage regarding maneuverability.",
        description_long:
          "Plasma has a truly destructive power due to its ability to store large amounts of energy. In combination with laser and ion technology, the plasma could be stabilized for the first time and thus fired at targets using high-kinetic launchers. When it hits enemy weapons and navigation systems, the electrical conductivity of plasma will bypass circuits for truly devastating damage regarding maneuverability. A failure of the electrical systems renders enemy ships completely unusable and steers around in space as unmaneuverable space debris.",
        type: "defense",
        attack_value: 3000,
        shield_value: 300,
        hit_points: 10_000
      },
      # %{
      #   name: "Fortress",
      #   image_src: "/images/units/.webp",
      #   description_short:
      #     "These massive defense rings are built around the planet's buildings and facilities. Due to their high durability, they drastically reduce the effectiveness of enemy attacks.",
      #   description_long:
      #     "These massive defense rings are built around the planet's buildings and facilities. Due to their high durability, they drastically reduce the effectiveness of enemy attacks. The construction of the complex is reminiscent of long-forgotten civilizations, that tried to protect their cities from invaders with stone walls. Of course, the materials used are not in the least comparable. In addition to protecting the infrastructure, the highly developed weapon systems can simultaneously defend entire cities by opening fire on the attacker at the same time. With every unit the thickness of fortress is being increased.",
      #   type: "defense",
      #   attack_value: 10_800,
      #   shield_value: 20_000,
      #   hit_points: 960_000
      # },
      # %{
      #   name: "Doom Cannon",
      #   image_src: "/images/units/.webp",
      #   description_short:
      #     "The doom cannon's massive blasts of energy can even hit multiple Death Stars and Avatars at once with their unimaginable level of destructive power.",
      #   description_long:
      #     "During the first test attempts by scientists, there was a short-term power failure when the cannons were used. Due to the total darkness combined with the rumbling sound, the inhabitants thought the planet was about to collapse. Since then, the huge cannons have been called \"Cannons of Doom\". Inside these cannons, graviton and plasma articles are first fused in a nuclear fusion. However, the unstable mixture implodes after a short time, so that the outer shells only have the purpose of directing the projectile in the approximate direction of the attacker. The enormous bursts of energy from the plasma-graviton-cannon can even hit several Death Stars and Avatars at once due to their unimaginable degree of destructive power.",
      #   type: "defense",
      #   attack_value: 20_000,
      #   shield_value: 120_000,
      #   hit_points: 3_600_000
      # },
      # %{
      #   name: "Orbital Defense Platform",
      #   image_src: "/images/units/.webp",
      #   description_short:
      #     "This massive defense system is integrated into the planet's orbit. Simultaneously firing at devastating proportions, she can destroy entire enemy fleets in one salvo.",
      #   description_long:
      #     "Due to the technological advancement of warships there was much need for a new defence system to counter massive enemy fleets. This massive defense system is integrated into the planet's orbit. Simultaneously firing at devastating proportions, she can destroy entire enemy fleets in one salvo.",
      #   type: "defense",
      #   attack_value: 96_000,
      #   shield_value: 1_000_000,
      #   hit_points: 22_400_000
      # },
      %{
        name: "Small Shield Dome",
        image_src: "/images/units/small-shield.webp",
        description_short:
          "The small shield dome covers the defense units and ships with a protective energy shield using a generator. This can absorb additional energy from the outside and is still permeable enough to let your own defenses fire.",
        description_long:
          "The small shield dome covers facilities and units with a protective energy shield using a generator. This can absorb additional energy from the outside and is still permeable enough to let own defense systems fire. Due to the high energy voltage required, only a limited number of shield domes can be built per planet. This amount can be increased by the ongoing progress of the empire.",
        type: "defense",
        attack_value: 0,
        shield_value: 2000,
        hit_points: 4000
      },
      %{
        name: "Large Shield Dome",
        image_src: "/images/units/large-shield.webp",
        description_short:
          "Further research into shield technologies has significantly improved the resilience of small shield domes. Large shield domes thus cover a much larger area of the planet, which means that its facilities and units can be protected much more efficiently.",
        description_long:
          "Further research into shield technologies has significantly improved the resilience of small shield domes. Large shield domes thus cover a much larger area of the planet, which means that more facilities and units can be protected more efficiently. Due to the high energy voltage required, only a limited number of shield domes can be built per planet. That number can be increased by ongoing progress of the empire.",
        type: "defense",
        attack_value: 0,
        shield_value: 10_000,
        hit_points: 20_000
      },
      # %{
      #   name: "Atmospheric Shield",
      #   image_src: "/images/units/.webp",
      #   description_short:
      #     "These vast energy shields reinforce a planet's natural atmosphere. They span the entire planet and, in conjunction with other defense systems, make it possible to withstand even major attacks without damage.",
      #   description_long:
      #     "These vast energy shields reinforce a planet's natural atmosphere. They span the entire planet and, in conjunction with other defense systems, make it possible to withstand even major attacks without damage. Due to the high energy voltage required, only a limited number of atmospheric shields can be built per planet.",
      #   type: "defense",
      #   attack_value: 0,
      #   shield_value: 2_000_000,
      #   hit_points: 4_000_000
      # },
      %{
        name: "Interceptor Missile",
        image_src: "/images/units/interceptor-missile.webp",
        description_short:
          "With this anti-ballistic missile defense system, incoming interplanetary missiles can be successfully shot down in the stratosphere.",
        description_long: "TBD",
        type: "missile",
        attack_value: 0,
        shield_value: 0,
        hit_points: 6500
      },
      %{
        name: "Interplanetary Missile",
        image_src: "/images/units/interplanetary-missile.webp",
        description_short:
          "The plasma warheads used by the interplanetary missiles cause devastating damage to enemy defense systems - if they are not protected by interceptor missiles. Defenses destroyed by missiles are not restored.",
        description_long:
          "Interplanetary missiles represent the further development of long-distance missiles already known from the 20th century. However, escaping the atmosphere of a planet without triggering the sensitive explosive device posed a challenge for the developers for a long time. By exploiting robotic and nanite technology, the interplanetary missiles can now be mass-produced. The main costs are related to the filling of the huge deuterium tanks, which are required for the launch of the missiles. The detonating plasma warheads lead to devastating damage to enemy defense systems - if they are not protected by interceptor missiles. Defenses destroyed by missiles are not restored.",
        type: "missile",
        attack_value: 15_000,
        shield_value: 0,
        hit_points: 12_500
      }
    ]
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_player_session_token(token) do
    Repo.delete_all(PlayerToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given player.

  ## Examples

      iex> deliver_player_confirmation_instructions(player, &url(~p"/players/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_player_confirmation_instructions(confirmed_player, &url(~p"/players/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_player_confirmation_instructions(%Player{} = player, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if player.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, player_token} = PlayerToken.build_email_token(player, "confirm")
      Repo.insert!(player_token)

      PlayerNotifier.deliver_confirmation_instructions(
        player,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a player by the given token.

  If the token matches, the player account is marked as confirmed
  and the token is deleted.
  """
  def confirm_player(token) do
    with {:ok, query} <- PlayerToken.verify_email_token_query(token, "confirm"),
         %Player{} = player <- Repo.one(query),
         {:ok, %{player: player}} <- Repo.transaction(confirm_player_multi(player)) do
      {:ok, player}
    else
      _ -> :error
    end
  end

  defp confirm_player_multi(player) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:player, Player.confirm_changeset(player))
    |> Ecto.Multi.delete_all(
      :tokens,
      PlayerToken.by_player_and_contexts_query(player, ["confirm"])
    )
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given player.

  ## Examples

      iex> deliver_player_reset_password_instructions(player, &url(~p"/players/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_player_reset_password_instructions(%Player{} = player, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, player_token} = PlayerToken.build_email_token(player, "reset_password")
    Repo.insert!(player_token)

    PlayerNotifier.deliver_reset_password_instructions(
      player,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the player by reset password token.

  ## Examples

      iex> get_player_by_reset_password_token("validtoken")
      %Player{}

      iex> get_player_by_reset_password_token("invalidtoken")
      nil

  """
  def get_player_by_reset_password_token(token) do
    with {:ok, query} <- PlayerToken.verify_email_token_query(token, "reset_password"),
         %Player{} = player <- Repo.one(query) do
      player
    else
      _ -> nil
    end
  end

  @doc """
  Resets the player password.

  ## Examples

      iex> reset_player_password(player, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Player{}}

      iex> reset_player_password(player, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_player_password(player, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:player, Player.password_changeset(player, attrs))
    |> Ecto.Multi.delete_all(:tokens, PlayerToken.by_player_and_contexts_query(player, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{player: player}} -> {:ok, player}
      {:error, :player, changeset, _} -> {:error, changeset}
    end
  end
end
