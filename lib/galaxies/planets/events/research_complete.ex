defmodule Galaxies.Planets.Events.ResearchComplete do
  alias Galaxies.Planets.PlanetEvent

  alias Galaxies.Planets.Events.ResearchEvent
  alias Galaxies.PlayerResearch

  import Ecto.Query

  def process(%PlanetEvent{type: :research_complete} = event, planet_id) do
    %{
      research_event: %ResearchEvent{research_id: research_id}
    } = event

    Ecto.Multi.new()
    |> Ecto.Multi.run(:update_research, fn repo, _changes ->
      from(pr in PlayerResearch,
        where: pr.research_id == ^research_id,
        update: [inc: [level: 1]]
      )
      |> repo.update_all([])

      {:ok, nil}
    end)
    |> Ecto.Multi.run(:maybe_start_next_research, fn repo, _changes ->
      research_queue =
        repo.all(
          from(pe in PlanetEvent,
            where: not pe.is_processed and not pe.is_cancelled and pe.type == ^:research_complete
          )
        )
        
      

      {:ok, nil}
    end)
    |> Repo.transaction()
  end
end
