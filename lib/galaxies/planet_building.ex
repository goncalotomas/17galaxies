defmodule Galaxies.PlanetBuilding do
  use Galaxies.Schema

  import Ecto.Changeset

  @primary_key false
  schema "planet_buildings" do
    field :current_level, :integer
    field :is_upgrading, :boolean
    field :upgrade_finish_time, :utc_datetime

    belongs_to :planet, Galaxies.Planet, primary_key: true
    belongs_to :building, Galaxies.Building, primary_key: true

    timestamps(type: :utc_datetime_usec)
  end

  def upgrade_changeset(planet_building, attrs) do
    planet_building
    |> cast(attrs, [:current_level])
  end
end
