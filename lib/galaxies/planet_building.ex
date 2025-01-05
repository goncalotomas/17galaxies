defmodule Galaxies.PlanetBuilding do
  use Galaxies.Schema

  import Ecto.Changeset

  @primary_key false
  schema "planet_buildings" do
    field :current_level, :integer

    belongs_to :planet, Galaxies.Planet, primary_key: true, type: :integer
    belongs_to :building, Galaxies.Building, primary_key: true, type: :integer

    timestamps(type: :utc_datetime_usec)
  end

  def enqueue_upgrade_changeset(planet_building, attrs) do
    planet_building
    |> cast(attrs, [:is_upgrading, :upgrade_finished_at])
  end

  def complete_upgrade_changeset(planet_building, attrs) do
    planet_building
    |> cast(attrs, [:current_level, :is_upgrading, :upgrade_finished_at])
  end
end
