defmodule GalaxiesWeb.ResearchLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  describe "when player is logged out" do
    test "redirects to login page", %{conn: conn} do
      result =
        conn
        |> live(~p"/research")
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
      {:ok, view, _html} = live(conn, ~p"/research")

      metal = element(view, "#planet_resources", "Metal")
      crystal = element(view, "#planet_resources", "Crystal")
      deuterium = element(view, "#planet_resources", "Deuterium")
      energy = element(view, "#planet_resources", "Energy")

      assert has_element?(metal)
      assert has_element?(crystal)
      assert has_element?(deuterium)
      assert has_element?(energy)
    end

    test "displays player researches", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/research")

      assert html =~ "Espionage Technology"
      assert html =~ "Computer Technology"
      assert html =~ "Energy Technology"
      assert html =~ "Laser Technology"
      assert html =~ "Ion Technology"
      assert html =~ "Plasma Technology"
      assert html =~ "Graviton Technology"
      assert html =~ "Weapons Technology"
      assert html =~ "Shields Technology"
      assert html =~ "Armor Technology"
      assert html =~ "Hyperspace Technology"
      assert html =~ "Combustion Engine Technology"
      assert html =~ "Hyperspace Engine Technology"
      assert html =~ "Astrophysics Technology"
      assert html =~ "Intergalactic Research Network"
    end
  end
end
