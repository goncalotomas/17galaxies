defmodule Galaxies.Planets.Event do
  @moduledoc """
  A planet event is an event that occurs on a planet,
  typically some time after an action was taken.
  As an example, a player may perform an action to upgrade a building on a planet,
  which has immediate effects, but the building upgrade will only complete at a later time.
  """

  @callback process(%Galaxies.Planets.PlanetEvent{}, planet_id :: integer()) ::
              {:ok, nil} | {:error, map()}
end
