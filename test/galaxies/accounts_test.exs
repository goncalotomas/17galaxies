defmodule Galaxies.AccountsTest do
  use Galaxies.DataCase

  alias Galaxies.Accounts

  import Galaxies.AccountsFixtures
  alias Galaxies.Accounts.{Player, PlayerToken}

  describe "get_player_by_email/1" do
    test "does not return the player if the email does not exist" do
      refute Accounts.get_player_by_email("unknown@example.com")
    end

    test "returns the player if the email exists" do
      %{id: id} = player = player_fixture()
      assert %Player{id: ^id} = Accounts.get_player_by_email(player.email)
    end
  end

  describe "get_player_by_email_and_password/2" do
    test "does not return the player if the email does not exist" do
      refute Accounts.get_player_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the player if the password is not valid" do
      player = player_fixture()
      refute Accounts.get_player_by_email_and_password(player.email, "invalid")
    end

    test "returns the player if the email and password are valid" do
      %{id: id} = player = player_fixture()

      assert %Player{id: ^id} =
               Accounts.get_player_by_email_and_password(player.email, valid_player_password())
    end
  end

  describe "get_player!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_player!(Ecto.UUID.generate())
      end
    end

    test "returns the player with the given id" do
      %{id: id} = player = player_fixture()
      assert %Player{id: ^id} = Accounts.get_player!(player.id)
    end
  end

  describe "register_player/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_player(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_player(%{
          username: "not  valid",
          email: "not valid",
          password: "not valid"
        })

      assert %{
               username: [
                 "Must include characters a-z, A-Z, 0-9 or '_'. Cannot start or end with '_'.\nMust not include multiple consecutive '_'.\n"
               ],
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_player(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = player_fixture()
      {:error, changeset} = Accounts.register_player(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_player(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers players with a hashed password" do
      email = unique_player_email()
      {:ok, player} = Accounts.register_player(valid_player_attributes(email: email))
      assert player.email == email
      assert is_binary(player.hashed_password)
      assert is_nil(player.confirmed_at)
      assert is_nil(player.password)
    end
  end

  describe "change_player_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_player_registration(%Player{})
      assert changeset.required == [:username, :password, :email]
    end

    test "allows fields to be set" do
      email = unique_player_email()
      password = valid_player_password()

      changeset =
        Accounts.change_player_registration(
          %Player{},
          valid_player_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_player_email/2" do
    test "returns a player changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_player_email(%Player{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_player_email/3" do
    setup do
      %{player: player_fixture()}
    end

    test "requires email to change", %{player: player} do
      {:error, changeset} = Accounts.apply_player_email(player, valid_player_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{player: player} do
      {:error, changeset} =
        Accounts.apply_player_email(player, valid_player_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{player: player} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_player_email(player, valid_player_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{player: player} do
      %{email: email} = player_fixture()
      password = valid_player_password()

      {:error, changeset} = Accounts.apply_player_email(player, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{player: player} do
      {:error, changeset} =
        Accounts.apply_player_email(player, "invalid", %{email: unique_player_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{player: player} do
      email = unique_player_email()

      {:ok, player} =
        Accounts.apply_player_email(player, valid_player_password(), %{email: email})

      assert player.email == email
      assert Accounts.get_player!(player.id).email != email
    end
  end

  describe "deliver_player_update_email_instructions/3" do
    setup do
      %{player: player_fixture()}
    end

    test "sends token through notification", %{player: player} do
      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_update_email_instructions(player, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert player_token = Repo.get_by(PlayerToken, token: :crypto.hash(:sha256, token))
      assert player_token.player_id == player.id
      assert player_token.sent_to == player.email
      assert player_token.context == "change:current@example.com"
    end
  end

  describe "update_player_email/2" do
    setup do
      player = player_fixture()
      email = unique_player_email()

      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_update_email_instructions(
            %{player | email: email},
            player.email,
            url
          )
        end)

      %{player: player, token: token, email: email}
    end

    test "updates the email with a valid token", %{player: player, token: token, email: email} do
      assert Accounts.update_player_email(player, token) == :ok
      changed_player = Repo.get!(Player, player.id)
      assert changed_player.email != player.email
      assert changed_player.email == email
      assert changed_player.confirmed_at
      assert changed_player.confirmed_at != player.confirmed_at
      refute Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not update email with invalid token", %{player: player} do
      assert Accounts.update_player_email(player, "oops") == :error
      assert Repo.get!(Player, player.id).email == player.email
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not update email if player email changed", %{player: player, token: token} do
      assert Accounts.update_player_email(%{player | email: "current@example.com"}, token) ==
               :error

      assert Repo.get!(Player, player.id).email == player.email
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not update email if token expired", %{player: player, token: token} do
      {1, nil} = Repo.update_all(PlayerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_player_email(player, token) == :error
      assert Repo.get!(Player, player.id).email == player.email
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end
  end

  describe "change_player_password/2" do
    test "returns a player changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_player_password(%Player{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_player_password(%Player{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_player_password/3" do
    setup do
      %{player: player_fixture()}
    end

    test "validates password", %{player: player} do
      {:error, changeset} =
        Accounts.update_player_password(player, valid_player_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{player: player} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_player_password(player, valid_player_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{player: player} do
      {:error, changeset} =
        Accounts.update_player_password(player, "invalid", %{password: valid_player_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{player: player} do
      {:ok, player} =
        Accounts.update_player_password(player, valid_player_password(), %{
          password: "new valid password"
        })

      assert is_nil(player.password)
      assert Accounts.get_player_by_email_and_password(player.email, "new valid password")
    end

    test "deletes all tokens for the given player", %{player: player} do
      _ = Accounts.generate_player_session_token(player)

      {:ok, _} =
        Accounts.update_player_password(player, valid_player_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(PlayerToken, player_id: player.id)
    end
  end

  describe "generate_player_session_token/1" do
    setup do
      %{player: player_fixture()}
    end

    test "generates a token", %{player: player} do
      token = Accounts.generate_player_session_token(player)
      assert player_token = Repo.get_by(PlayerToken, token: token)
      assert player_token.context == "session"

      # Creating the same token for another player should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%PlayerToken{
          token: player_token.token,
          player_id: player_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_player_by_session_token/1" do
    setup do
      player = player_fixture()
      token = Accounts.generate_player_session_token(player)
      %{player: player, token: token}
    end

    test "returns player by token", %{player: player, token: token} do
      assert session_player = Accounts.get_player_by_session_token(token)
      assert session_player.id == player.id
    end

    test "does not return player for invalid token" do
      refute Accounts.get_player_by_session_token("oops")
    end

    test "does not return player for expired token", %{token: token} do
      {1, nil} = Repo.update_all(PlayerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_player_by_session_token(token)
    end
  end

  describe "delete_player_session_token/1" do
    test "deletes the token" do
      player = player_fixture()
      token = Accounts.generate_player_session_token(player)
      assert Accounts.delete_player_session_token(token) == :ok
      refute Accounts.get_player_by_session_token(token)
    end
  end

  describe "deliver_player_confirmation_instructions/2" do
    setup do
      %{player: player_fixture()}
    end

    test "sends token through notification", %{player: player} do
      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_confirmation_instructions(player, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert player_token = Repo.get_by(PlayerToken, token: :crypto.hash(:sha256, token))
      assert player_token.player_id == player.id
      assert player_token.sent_to == player.email
      assert player_token.context == "confirm"
    end
  end

  describe "confirm_player/1" do
    setup do
      player = player_fixture()

      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_confirmation_instructions(player, url)
        end)

      %{player: player, token: token}
    end

    test "confirms the email with a valid token", %{player: player, token: token} do
      assert {:ok, confirmed_player} = Accounts.confirm_player(token)
      assert confirmed_player.confirmed_at
      assert confirmed_player.confirmed_at != player.confirmed_at
      assert Repo.get!(Player, player.id).confirmed_at
      refute Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not confirm with invalid token", %{player: player} do
      assert Accounts.confirm_player("oops") == :error
      refute Repo.get!(Player, player.id).confirmed_at
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not confirm email if token expired", %{player: player, token: token} do
      {1, nil} = Repo.update_all(PlayerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_player(token) == :error
      refute Repo.get!(Player, player.id).confirmed_at
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end
  end

  describe "deliver_player_reset_password_instructions/2" do
    setup do
      %{player: player_fixture()}
    end

    test "sends token through notification", %{player: player} do
      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_reset_password_instructions(player, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert player_token = Repo.get_by(PlayerToken, token: :crypto.hash(:sha256, token))
      assert player_token.player_id == player.id
      assert player_token.sent_to == player.email
      assert player_token.context == "reset_password"
    end
  end

  describe "get_player_by_reset_password_token/1" do
    setup do
      player = player_fixture()

      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_reset_password_instructions(player, url)
        end)

      %{player: player, token: token}
    end

    test "returns the player with valid token", %{player: %{id: id}, token: token} do
      assert %Player{id: ^id} = Accounts.get_player_by_reset_password_token(token)
      assert Repo.get_by(PlayerToken, player_id: id)
    end

    test "does not return the player with invalid token", %{player: player} do
      refute Accounts.get_player_by_reset_password_token("oops")
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end

    test "does not return the player if token expired", %{player: player, token: token} do
      {1, nil} = Repo.update_all(PlayerToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_player_by_reset_password_token(token)
      assert Repo.get_by(PlayerToken, player_id: player.id)
    end
  end

  describe "reset_player_password/2" do
    setup do
      %{player: player_fixture()}
    end

    test "validates password", %{player: player} do
      {:error, changeset} =
        Accounts.reset_player_password(player, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{player: player} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_player_password(player, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{player: player} do
      {:ok, updated_player} =
        Accounts.reset_player_password(player, %{password: "new valid password"})

      assert is_nil(updated_player.password)
      assert Accounts.get_player_by_email_and_password(player.email, "new valid password")
    end

    test "deletes all tokens for the given player", %{player: player} do
      _ = Accounts.generate_player_session_token(player)
      {:ok, _} = Accounts.reset_player_password(player, %{password: "new valid password"})
      refute Repo.get_by(PlayerToken, player_id: player.id)
    end
  end

  describe "inspect/2 for the Player module" do
    test "does not include password" do
      refute inspect(%Player{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
