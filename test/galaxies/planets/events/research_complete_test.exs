defmodule Galaxies.Planets.Events.ResearchCompleteTest do
  use Galaxies.DataCase, async: true

  alias Galaxies.Planets.Events.ResearchComplete

  test "process/2 returns :ok" do
    event = %Galaxies.Planets.PlanetEvent{type: :research_complete}
    assert ResearchComplete.process(event, 1) == :ok
  end
end
