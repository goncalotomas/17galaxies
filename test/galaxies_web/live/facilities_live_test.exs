defmodule GalaxiesWeb.FacilitiesLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "when player is logged out" do
    test "redirects to login page", %{conn: conn} do
      result =
        conn
        |> live(~p"/facilities")
        |> follow_redirect(conn, "/players/log_in")

      assert {:ok, _conn} = result
    end
  end

  describe "when player is logged in" do
    setup %{conn: conn} do
      player = player_fixture()

      [
        conn: log_in_player(conn, player),
        player: player
      ]
    end

    test "displays current planet resources", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/facilities")

      metal = element(view, "#planet_resources", "Metal")
      crystal = element(view, "#planet_resources", "Crystal")
      deuterium = element(view, "#planet_resources", "Deuterium")
      energy = element(view, "#planet_resources", "Energy")

      assert has_element?(metal)
      assert has_element?(crystal)
      assert has_element?(deuterium)
      assert has_element?(energy)
    end

    test "displays planet's facilities buildings", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/facilities")

      refute html =~ "Metal Mine"
      refute html =~ "Crystal Mine"
      refute html =~ "Deuterium Synthesizer"
      refute html =~ "Solar Power Plant"
      refute html =~ "Fusion Reactor"
      refute html =~ "Metal Storage"
      refute html =~ "Crystal Storage"
      refute html =~ "Deuterium Tank"

      # ensure facility buildings don't show up
      assert html =~ "Robot Factory"
      assert html =~ "Nanite Factory"
      # shipyard assertion will always pass due to this string being in the user navigation.
      assert html =~ "Shipyard"
      assert html =~ "Research Lab"
      assert html =~ "Terraformer"
      assert html =~ "Missile Silo"
    end
  end
end
