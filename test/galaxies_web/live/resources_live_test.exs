defmodule GalaxiesWeb.ResourcesLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "when player is logged out" do
    test "redirects to login page", %{conn: conn} do
      result =
        conn
        |> live(~p"/resources")
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
      {:ok, view, _html} = live(conn, ~p"/overview")

      metal = element(view, "#planet_resources", "Metal")
      crystal = element(view, "#planet_resources", "Crystal")
      deuterium = element(view, "#planet_resources", "Deuterium")
      energy = element(view, "#planet_resources", "Energy")

      assert has_element?(metal)
      assert has_element?(crystal)
      assert has_element?(deuterium)
      assert has_element?(energy)
    end

    test "displays planet's resource buildings", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/resources")

      assert html =~ "Metal Mine"
      assert html =~ "Crystal Mine"
      assert html =~ "Deuterium Synthesizer"
      assert html =~ "Solar Power Plant"
      assert html =~ "Fusion Reactor"
      assert html =~ "Metal Storage"
      assert html =~ "Crystal Storage"
      assert html =~ "Deuterium Tank"

      # ensure facility buildings don't show up
      refute html =~ "Robot Factory"
      refute html =~ "Nanite Factory"
      # Can't refute on the string Shipyard since it shows up in user navigation.
      # refute html =~ "Shipyard"
      refute html =~ "Research Lab"
      refute html =~ "Terraformer"
      refute html =~ "Missile Silo"
    end
  end
end
