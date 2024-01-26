defmodule Galaxies.PlanetBuilding do
  use Galaxies.Schema

  schema "planet_buildings" do
    field :current_level, :integer
    field :is_upgrading, :boolean
    field :upgrade_finish_time, :utc_datetime

    belongs_to :planet, Galaxies.Planet
    belongs_to :building, Galaxies.Building, type: :integer

    timestamps(type: :utc_datetime_usec)
  end
end
