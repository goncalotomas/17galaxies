defmodule GalaxiesWeb.PlayerSessionControllerTest do
  use GalaxiesWeb.ConnCase, async: true

  import Galaxies.AccountsFixtures

  setup do
    %{player: player_fixture()}
  end

  describe "POST /players/log_in" do
    test "logs the player in", %{conn: conn, player: player} do
      conn =
        post(conn, ~p"/players/log_in", %{
          "player" => %{"email" => player.email, "password" => valid_player_password()}
        })

      assert get_session(conn, :player_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ player.email
      assert response =~ ~p"/players/settings"
      assert response =~ ~p"/players/log_out"
    end

    test "logs the player in with remember me", %{conn: conn, player: player} do
      conn =
        post(conn, ~p"/players/log_in", %{
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_galaxies_web_player_remember_me"]
      assert redirected_to(conn) == ~p"/"
    end

    test "logs the player in with return to", %{conn: conn, player: player} do
      conn =
        conn
        |> init_test_session(player_return_to: "/foo/bar")
        |> post(~p"/players/log_in", %{
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome back!"
    end

    test "login following registration", %{conn: conn, player: player} do
      conn =
        conn
        |> post(~p"/players/log_in", %{
          "_action" => "registered",
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password()
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Account created successfully"
    end

    test "login following password update", %{conn: conn, player: player} do
      conn =
        conn
        |> post(~p"/players/log_in", %{
          "_action" => "password_updated",
          "player" => %{
            "email" => player.email,
            "password" => valid_player_password()
          }
        })

      assert redirected_to(conn) == ~p"/players/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password updated successfully"
    end

    test "redirects to login page with invalid credentials", %{conn: conn} do
      conn =
        post(conn, ~p"/players/log_in", %{
          "player" => %{"email" => "invalid@email.com", "password" => "invalid_password"}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/players/log_in"
    end
  end

  describe "DELETE /players/log_out" do
    test "logs the player out", %{conn: conn, player: player} do
      conn = conn |> log_in_player(player) |> delete(~p"/players/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :player_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the player is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/players/log_out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :player_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
