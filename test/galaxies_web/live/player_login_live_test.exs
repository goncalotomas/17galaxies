defmodule GalaxiesWeb.PlayerLoginLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/players/log_in")

      assert html =~ "Sign in"
      assert html =~ "Sign up"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_player(player_fixture())
        |> live(~p"/players/log_in")
        |> follow_redirect(conn, "/overview")

      assert {:ok, _conn} = result
    end
  end

  describe "player login" do
    test "redirects if player login with valid credentials", %{conn: conn} do
      password = "123456789abcd"
      player = player_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/players/log_in")

      form =
        form(lv, "#login_form", player: %{email: player.email, password: password, remember_me: true})

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/overview"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/players/log_in")

      form =
        form(lv, "#login_form",
          player: %{email: "test@email.com", password: "123456", remember_me: true}
        )

      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"

      assert redirected_to(conn) == "/players/log_in"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/log_in")

      {:ok, _login_live, login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign up")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/players/register")

      assert login_html =~ "Register"
    end

    test "redirects to forgot password page when the Forgot Password button is clicked", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/players/log_in")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Forgot your password?")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/players/reset_password")

      assert conn.resp_body =~ "Forgot your password?"
    end
  end
end
