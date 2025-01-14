defmodule Galaxies.Planets.Events.ResearchComplete do
  alias Galaxies.Planets.PlanetEvent

  def process(%PlanetEvent{type: :research_complete} = _event, _planet_id) do
    :ok
  end
end
