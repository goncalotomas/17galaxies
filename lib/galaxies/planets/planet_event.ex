defmodule Galaxies.Planets.PlanetEvent do
  @moduledoc """
  The schema for PlanetEventQueue.
  """
  use Galaxies.Schema

  @atom_values_mapping [building_construction: 1, technology_research_complete: 2]

  schema "planet_events" do
    # this type allows storing primary keys from multiple tables so that we can have
    # separate queues for buildings, research and shipyard construction.
    field :type, Ecto.Enum,
      values: @atom_values_mapping,
      null: false

    field :event_id, :binary_id
    field :data, :map

    field :completed_at, :utc_datetime

    belongs_to :planet, Galaxies.Planet, type: :integer

    timestamps(updated_at: false, type: :utc_datetime)
  end
end
