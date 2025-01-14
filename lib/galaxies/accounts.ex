defmodule Galaxies.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Galaxies.Planets
  alias Galaxies.Planet
  alias Galaxies.Repo
  alias Galaxies.Planets.PlanetEvent

  alias Galaxies.Accounts.{Player, PlayerToken, PlayerNotifier}
  alias Galaxies.{Building, PlanetBuilding, PlanetUnit, PlayerResearch, Research, Unit}

  require Logger

  ## PlanetBuilding operations

  @doc """
  Tries to upgrade a planet building.
  """
  def upgrade_planet_building(planet, building_id, level) do
    # TODO maybe wrap in transaction
    now = DateTime.utc_now()

    with {:prerequisites_ok, true} <-
           {:prerequisites_ok, Planets.can_build_building?(planet, building_id)},
         :ok <- Planets.enqueue_building(planet.id, building_id, level),
         :ok <- Planets.process_planet_events(planet.id, now) do
      :ok
    else
      {:prerequisites_ok, false} ->
        {:error, :unmet_prerequisites}
    end
  end

  ## Player Researches

  @doc """
  Upgrades a player's research from a specific planet
  """
  def upgrade_player_research(player, planet, research_id, level) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:player_research, fn repo, _changes ->
      player_research =
        repo.one!(
          from pr in PlayerResearch,
            where: pr.research_id == ^research_id and pr.player_id == ^player.id,
            preload: :research
        )

      if player_research.level == level - 1 do
        {:ok, _} =
          Repo.update(
            PlayerResearch.upgrade_changeset(player_research, %{
              level: level
            })
          )

        {:ok, player_research}
      else
        {:error, "Cannot upgrade from level #{player_research.level} to #{level}"}
      end
    end)
    |> Ecto.Multi.run(:update_planet, fn repo, %{player_research: player_research} ->
      planet =
        repo.one!(
          from p in Planet,
            where: p.id == ^planet.id,
            select: p
        )

      research = player_research.research

      {metal, crystal, deuterium, energy} =
        Galaxies.calc_upgrade_cost(research.upgrade_cost_formula, level)

      if planet.metal_units >= metal and planet.crystal_units >= crystal and
           planet.deuterium_units >= deuterium and planet.total_energy >= energy do
        {:ok, _} =
          Repo.update(
            Planet.upgrade_research_changeset(planet, %{
              metal_units: planet.metal_units - metal,
              crystal_units: planet.crystal_units - crystal,
              deuterium_units: planet.deuterium_units - deuterium
            })
          )

        {:ok, planet.used_fields + 1}
      else
        {:error, "Not enough resources on #{planet.name} to build #{research.name}"}
      end
    end)
    |> Repo.transaction()
    |> then(fn
      {:ok, result} -> {:ok, result}
      {:error, _step, error, _partial_changes} -> {:error, error}
    end)
  end

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

  def get_fleet_events(player_id) do
    Repo.all(
      from pe in PlanetEvent,
        join: p in Planet,
        on: pe.planet_id == p.id and p.player_id == ^player_id,
        where: pe.type in ^PlanetEvent.get_fleet_event_ids()
    )
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
    now = DateTime.utc_now()

    attrs =
      Enum.reduce(attrs, %{}, fn
        {key, value}, acc when is_atom(key) -> Map.put(acc, key, value)
        {key, value}, acc when is_binary(key) -> Map.put(acc, String.to_existing_atom(key), value)
      end)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:home_planet_id, fn repo, _changes ->
      query = "select nextval('planets_id_seq')"
      %{rows: [[id]]} = Ecto.Adapters.SQL.query!(repo, query)

      {:ok, id}
    end)
    |> Ecto.Multi.run(:player, fn repo, %{home_planet_id: home_planet_id} ->
      player_changeset =
        Player.registration_changeset(
          %Player{},
          Map.put(attrs, :current_planet_id, home_planet_id)
        )

      repo.insert(player_changeset)
    end)
    |> Ecto.Multi.run(:player_researches, fn repo, %{player: player} ->
      player_researches =
        repo.all(from(r in Research))
        |> Enum.map(fn research ->
          %{
            player_id: player.id,
            research_id: research.id,
            level: 0,
            inserted_at: now,
            updated_at: now
          }
        end)

      {player_researches, nil} = repo.insert_all(PlayerResearch, player_researches)

      Logger.debug(
        "inserted #{player_researches} player_researches for player #{player.username}"
      )

      {:ok, nil}
    end)
    |> Ecto.Multi.insert(:planet, fn %{home_planet_id: home_planet_id, player: player} ->
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
        image_id: 1,
        metal_units: 5_000.0,
        crystal_units: 5_000.0,
        deuterium_units: 500.0,
        total_energy: 0,
        available_energy: 0,
        total_fields: 250,
        used_fields: 0
      })
    end)
    |> Ecto.Multi.run(:planet_buildings, fn repo, %{player: player, planet: planet} ->
      planet_buildings =
        repo.all(from(b in Building))
        |> Enum.map(fn building ->
          %{
            planet_id: planet.id,
            building_id: building.id,
            level: 0,
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
    |> Ecto.Multi.run(:planet_units, fn repo, %{player: player, planet: planet} ->
      planet_units =
        repo.all(from(u in Unit))
        |> Enum.map(fn unit ->
          %{
            planet_id: planet.id,
            unit_id: unit.id,
            amount: 0,
            inserted_at: now,
            updated_at: now
          }
        end)

      {unit_count, nil} = repo.insert_all(PlanetUnit, planet_units)

      Logger.debug(
        "inserted #{unit_count} planet_units for planet #{planet.name} of #{player.username}"
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
    Planet
    |> where([p], p.id == ^player.current_planet_id)
    |> select([p], p)
    |> preload([p], [:buildings])
    |> Repo.one!()
  end

  @doc """
  Returns the galaxy view for a particular galaxy solar system.
  Currently returning a stubbed response.
  """
  def get_galaxy_view(galaxy, system) do
    # TODO clear out resources from results or use a different schema for galaxy-view Planets.
    # Same for the Player information returned in this query.
    Repo.all(
      from p in Planet,
        where: p.galaxy == ^galaxy and p.system == ^system,
        preload: [:player]
    )
  end

  @doc """
  Gets the resource buildings for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_resource_buildings(planet) do
    query =
      from building in Building,
        where: building.type == :resource,
        join: planet_building in PlanetBuilding,
        on: building.id == planet_building.building_id,
        where: planet_building.planet_id == ^planet.id,
        select: %{
          id: building.id,
          name: building.name,
          description_short: building.short_description,
          description_long: building.long_description,
          image_src: building.image_src,
          level: planet_building.level,
          upgrade_cost_formula: building.upgrade_cost_formula
        },
        order_by: [building.list_order]

    Repo.all(query)
  end

  @doc """
  Gets the facilities buildings for a specific planet.
  """
  def get_planet_facilities_buildings(planet) do
    query =
      from building in Building,
        where: building.type == :facility,
        join: planet_building in PlanetBuilding,
        on: building.id == planet_building.building_id,
        where: planet_building.planet_id == ^planet.id,
        select: %{
          id: building.id,
          name: building.name,
          description_short: building.short_description,
          description_long: building.long_description,
          image_src: building.image_src,
          level: planet_building.level,
          upgrade_cost_formula: building.upgrade_cost_formula
        },
        order_by: [building.list_order]

    Repo.all(query)
  end

  @doc """
  Gets the research for a specific player.
  """
  def get_player_researches(player) do
    query =
      from research in Research,
        join: player_research in PlayerResearch,
        on: research.id == player_research.research_id,
        where: player_research.player_id == ^player.id,
        select: %{
          id: research.id,
          name: research.name,
          description_short: research.short_description,
          description_long: research.long_description,
          image_src: research.image_src,
          level: player_research.level,
          upgrade_cost_formula: research.upgrade_cost_formula,
          is_upgrading: player_research.is_upgrading,
          upgrade_finished_at: player_research.upgrade_finished_at
        },
        order_by: [research.list_order]

    Repo.all(query)
  end

  @doc """
  Gets the ship units for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_ship_units(planet) do
    query =
      from unit in Unit,
        where: unit.type in [:ship, :planet_ship],
        join: planet_unit in PlanetUnit,
        on: unit.id == planet_unit.unit_id,
        where: planet_unit.planet_id == ^planet.id,
        select: %{
          id: unit.id,
          name: unit.name,
          description_short: unit.short_description,
          description_long: unit.long_description,
          image_src: unit.image_src,
          amount: planet_unit.amount,
          list_order: unit.list_order,
          unit_cost_metal: unit.unit_cost_metal,
          unit_cost_crystal: unit.unit_cost_crystal,
          unit_cost_deuterium: unit.unit_cost_deuterium
        },
        order_by: [unit.list_order]

    Repo.all(query)
  end

  @doc """
  Gets the defense units for a specific planet.
  Currently returning a stubbed response.
  """
  def get_planet_defense_units(planet) do
    query =
      from unit in Unit,
        where: unit.type in [:defense, :missile],
        join: planet_unit in PlanetUnit,
        on: unit.id == planet_unit.unit_id,
        where: planet_unit.planet_id == ^planet.id,
        select: %{
          id: unit.id,
          name: unit.name,
          description_short: unit.short_description,
          description_long: unit.long_description,
          image_src: unit.image_src,
          amount: planet_unit.amount,
          unit_cost_metal: unit.unit_cost_metal,
          unit_cost_crystal: unit.unit_cost_crystal,
          unit_cost_deuterium: unit.unit_cost_deuterium,
          unit_cost_energy: unit.unit_cost_energy
        },
        order_by: [unit.list_order]

    Repo.all(query)
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
