defmodule GalaxiesWeb.PlayerForgotPasswordLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  alias Galaxies.Accounts
  alias Galaxies.Repo

  describe "Forgot password page" do
    test "renders email page", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/players/reset_password")

      assert html =~ "Forgot your password?"
      assert has_element?(lv, ~s|a[href="#{~p"/players/register"}"]|, "Register")
      assert has_element?(lv, ~s|a[href="#{~p"/players/log_in"}"]|, "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_player(player_fixture())
        |> live(~p"/players/reset_password")
        |> follow_redirect(conn, ~p"/overview")

      assert {:ok, _conn} = result
    end
  end

  describe "Reset link" do
    setup do
      %{player: player_fixture()}
    end

    test "sends a new reset password token", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", player: %{"email" => player.email})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"

      assert Repo.get_by!(Accounts.PlayerToken, player_id: player.id).context ==
               "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/reset_password")

      {:ok, conn} =
        lv
        |> form("#reset_password_form", player: %{"email" => "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.PlayerToken) == []
    end
  end
end
