defmodule GalaxiesWeb.PlayerSettingsLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  alias Galaxies.Accounts
  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "Settings page" do
    test "renders settings page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_player(player_fixture())
        |> live(~p"/players/settings")

      assert html =~ "Change Email"
      assert html =~ "Change Password"
    end

    test "redirects if player is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/players/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "update email form" do
    setup %{conn: conn} do
      password = valid_player_password()
      player = player_fixture(%{password: password})
      %{conn: log_in_player(conn, player), player: player, password: password}
    end

    test "updates the player email", %{conn: conn, password: password, player: player} do
      new_email = unique_player_email()

      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => password,
          "player" => %{"email" => new_email}
        })
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_player_by_email(player.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> element("#email_form")
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "player" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#email_form", %{
          "current_password" => "invalid",
          "player" => %{"email" => player.email}
        })
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is not valid"
    end
  end

  describe "update password form" do
    setup %{conn: conn} do
      password = valid_player_password()
      player = player_fixture(%{password: password})
      %{conn: log_in_player(conn, player), player: player, password: password}
    end

    test "updates the player password", %{conn: conn, player: player, password: password} do
      new_password = valid_player_password()

      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      form =
        form(lv, "#password_form", %{
          "current_password" => password,
          "player" => %{
            "email" => player.email,
            "password" => new_password,
            "password_confirmation" => new_password
          }
        })

      render_submit(form)

      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/players/settings"

      assert get_session(new_password_conn, :player_token) != get_session(conn, :player_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_player_by_email_and_password(player.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> element("#password_form")
        |> render_change(%{
          "current_password" => "invalid",
          "player" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/settings")

      result =
        lv
        |> form("#password_form", %{
          "current_password" => "invalid",
          "player" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "should be at least 12 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is not valid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
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

      %{conn: log_in_player(conn, player), token: token, email: email, player: player}
    end

    test "updates the player email once", %{
      conn: conn,
      player: player,
      token: token,
      email: email
    } do
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_player_by_email(player.email)
      assert Accounts.get_player_by_email(email)

      # use confirm token again
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, player: player} do
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/settings"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_player_by_email(player.email)
    end

    test "redirects if player is not logged in", %{token: token} do
      conn = build_conn()
      {:error, redirect} = live(conn, ~p"/players/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/players/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end
