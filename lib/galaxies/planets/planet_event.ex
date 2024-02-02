defmodule Galaxies.Planets.PlanetEvent do
  @moduledoc """
  The schema for PlanetEventQueue.
  """
  use Galaxies.Schema

  @atom_values_mapping [building_construction_complete: 1, technology_research_complete: 2]

  schema "planet_events" do
    field :type, Ecto.Enum,
      values: @atom_values_mapping,
      null: false

    field :data, :map
    field :completed_at, :utc_datetime

    belongs_to :planet, Galaxies.Planet
  end
end
