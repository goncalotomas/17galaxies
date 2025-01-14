defmodule Galaxies.Planets.Events.BuildingEvent do
  @moduledoc """
  The schema for an enqueued building.
  """
  alias Galaxies.Building
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :duration_seconds, :integer
    field :demolish, :boolean, default: false

    belongs_to :building, Building
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:duration_seconds, :demolish, :building_id])
  end
end
