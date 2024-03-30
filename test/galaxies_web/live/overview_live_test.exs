defmodule GalaxiesWeb.OverviewLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "when player is logged out" do
    test "redirects to login page", %{conn: conn} do
      result =
        conn
        |> live(~p"/overview")
        |> follow_redirect(conn, "/players/log_in")

      assert {:ok, _conn} = result
    end
  end

  describe "when player is logged in" do
    setup %{conn: conn} do
      player = player_fixture()
      planet = Galaxies.Accounts.get_active_planet(player)

      [
        conn: log_in_player(conn, player),
        planet: planet,
        player: player
      ]
    end

    test "displays planet image and short summary", %{conn: conn, planet: planet} do
      {:ok, view, html} = live(conn, ~p"/overview")

      planet_image = element(view, ~s(img[src*="/images/planets/#{planet.image_id}/large.webp"]))

      assert has_element?(planet_image)

      assert html =~ "Overview — #{planet.name}"

      assert html =~ "Temperature:"
      assert html =~ "#{planet.min_temperature}°C"
      assert html =~ "#{planet.max_temperature}°C"

      assert html =~ "Diameter:"
      assert html =~ "#{planet.used_fields} / #{planet.total_fields} fields"

      assert html =~ "Coordinates:"
      planet_coordinates = "#{planet.galaxy}:#{planet.system}:#{planet.slot}"
      assert html =~ planet_coordinates
    end

    test "displays current planet resources", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/overview")

      metal = element(view, "#planet_metal")
      crystal = element(view, "#planet_resources", "Crystal")
      deuterium = element(view, "#planet_resources", "Deuterium")
      energy = element(view, "#planet_resources", "Energy")

      assert has_element?(metal)
      assert has_element?(crystal)
      assert has_element?(deuterium)
      assert has_element?(energy)
    end
  end
end
