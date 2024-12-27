defmodule SeventeenGalaxies.PlanetTest do
  use ExUnit.Case

  alias SeventeenGalaxies.Planet

  describe "planet schema" do
    test "creating a planet record with valid arguments works as expected" do
      %Planet{}
      |> Planet.changeset(%{name: "Alfa", galaxy: 17, solar_system: 17, solar_slot: 1})
    end
  end
end
