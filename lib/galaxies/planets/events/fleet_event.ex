defmodule Galaxies.Planets.Events.FleetEvent do
  @moduledoc """
  The schema for an enqueued building.
  """
  alias Galaxies.Planet
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :flight_duration_seconds, :integer

    belongs_to :planet, Planet
    belongs_to :fleet_in_motion, Galaxies.FleetInMotion
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:duration_seconds, :demolish, :building_id])
  end
end
