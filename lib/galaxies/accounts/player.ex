defmodule Galaxies.Accounts.Player do
  alias Galaxies.Planet
  use Galaxies.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "players" do
    field :email, :string
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :current_planet_id, :binary_id

    has_many :planets, Galaxies.Planet

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a query for fetching the active planet
  """
  def get_active_planet_query(player) do
    query =
      from player in __MODULE__,
        join: planet in Planet,
        on: planet.player_id == ^player.id,
        where: player.id == ^player.id and planet.id == ^player.current_planet_id,
        select: planet

    {:ok, query}
  end

  @doc """
  A player changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:email, :password, :username, :current_planet_id])
    |> validate_email(opts)
    |> validate_password(opts)
    |> validate_username(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Galaxies.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A player changeset for changing the username.

  It requires the username to change otherwise an error is added.
  """
  def username_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:username])
    |> validate_username(opts)
    |> case do
      %{changes: %{username: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :username, "did not change")
    end
  end

  defp validate_username(changeset, opts) do
    # ^(?![_])(?!.*[_]{2})[a-zA-Z0-9_]+(?<![_])$
    #  └───┬─┘└────┬─────┘└─────┬────┘ └───┬──┘
    #      │       │            │          │
    #      │       │            │        no _ at the end
    #      │       │            │
    #      │       │         allowed characters
    #      │       │
    #      │      no double _ inside
    #      │
    #    no _ at the beginning
    # modified version this regex: https://stackoverflow.com/a/12019115/3547126
    username_regex = ~r/^(?![_])(?!.*[_]{2})[a-zA-Z0-9_]+(?<![_])$/

    regex_message = """
    Must include characters a-z, A-Z, 0-9 or '_'. Cannot start or end with '_'.
    Must not include multiple consecutive '_'.
    """

    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3)
    |> validate_length(:username, max: 22)
    |> validate_format(:username, username_regex, message: regex_message)
    |> maybe_validate_unique_username(opts)
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> unsafe_validate_unique(:username, Galaxies.Repo)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  @doc """
  A player changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A player changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(player) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(player, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no player or the player doesn't have a password, we call
  `Argon2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Galaxies.Accounts.Player{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Argon2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
