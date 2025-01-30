defmodule Galaxies.Planets.Events.ResearchComplete do
  alias Galaxies.Planets.PlanetEvent

  alias Galaxies.Planets.Events.ResearchEvent
  alias Galaxies.PlayerResearch
  alias Galaxies.Planet
  alias Galaxies.Repo

  import Ecto.Query

  def process(%PlanetEvent{type: :research_complete} = event, _planet_id) do
    %ResearchEvent{player_id: player_id, research_id: research_id} = event.research_event

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
          from p in Planet,
            where: p.player_id == ^player_id,
            join: pe in assoc(p, :events),
            where: pe.type == ^:research_complete and not pe.is_processed and not pe.is_cancelled,
            select: pe,
            order_by: [asc: pe.inserted_at]
        )

      {:ok, research_queue}
    end)
    |> Repo.transaction()
  end
end
