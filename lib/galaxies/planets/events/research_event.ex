defmodule Galaxies.Planets.Events.ResearchEvent do
  @moduledoc """
  The schema for an enqueued building.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :duration_seconds, :integer
    field :player_id, :binary_id

    belongs_to :research, Galaxies.Research
    belongs_to :planet, Galaxies.Planet
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:player_id, :duration_seconds, :research_id, :planet_id])
  end
end
