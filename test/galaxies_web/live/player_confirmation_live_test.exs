defmodule GalaxiesWeb.PlayerConfirmationLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  alias Galaxies.Accounts
  alias Galaxies.Repo

  setup do
    %{player: player_fixture()}
  end

  describe "Confirm player" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/players/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "confirms the given token once", %{conn: conn, player: player} do
      token =
        extract_player_token(fn url ->
          Accounts.deliver_player_confirmation_instructions(player, url)
        end)

      {:ok, lv, _html} = live(conn, ~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/overview")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Player confirmed successfully"

      assert Accounts.get_player!(player.id).confirmed_at
      refute get_session(conn, :player_token)
      assert Repo.all(Accounts.PlayerToken) == []

      # when not logged in
      {:ok, lv, _html} = live(conn, ~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Player confirmation link is invalid or it has expired"

      # when logged in
      conn =
        build_conn()
        |> log_in_player(player)

      {:ok, lv, _html} = live(conn, ~p"/players/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/overview")

      assert {:ok, conn} = result
      refute Phoenix.Flash.get(conn.assigns.flash, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Player confirmation link is invalid or it has expired"

      refute Accounts.get_player!(player.id).confirmed_at
    end
  end
end
