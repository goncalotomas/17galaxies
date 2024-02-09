defmodule Galaxies.PlanetsTest do
  use Galaxies.DataCase, async: true
  import Galaxies.Factory

  alias Galaxies.Planets
  alias Galaxies.Planet

  setup do
    {:ok, planet: insert(:planet)}
  end

  describe "add_resources/4" do
    test "adds resources when called with positive amounts", %{planet: planet} do
      %{metal_units: metal, crystal_units: crystal, deuterium_units: deuterium} = planet
      Planets.add_resources(planet.id, 100, 100, 100)
      planet = Repo.get_by(Planet, id: planet.id)

      refute planet == nil
      assert planet.metal_units == metal + 100
      assert planet.crystal_units == crystal + 100
      assert planet.deuterium_units == deuterium + 100
    end

    test "subtracts resources when called with positive amounts", %{planet: planet} do
      %{metal_units: metal, crystal_units: crystal, deuterium_units: deuterium} = planet
      Planets.add_resources(planet.id, -1, -1, -1)
      planet = Repo.get_by(Planet, id: planet.id)

      refute planet == nil
      assert planet.metal_units == metal - 1
      assert planet.crystal_units == crystal - 1
      assert planet.deuterium_units == deuterium - 1
    end

    test "updates the planet's updated_at timestamp", %{planet: planet} do
      updated_at = planet.updated_at
      Planets.add_resources(planet.id, 100, 100, 100)
      planet = Repo.get_by(Planet, id: planet.id)
      refute DateTime.compare(updated_at, planet.updated_at) == :eq
    end
  end
end
