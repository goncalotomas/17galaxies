defmodule Galaxies.Planets.Events do
  @callback process(planet :: Galaxies.Planet, event :: Galaxies.Planets.PlanetEvent) ::
              Galaxies.Planet
end
