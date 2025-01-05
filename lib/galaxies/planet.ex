defmodule Galaxies.Planet do
  use Ecto.Schema

  import Ecto.Changeset

  schema "planets" do
    field :name, :string

    # planets are identified by a set of coordinates {galaxy, system, slot}
    field :galaxy, :integer
    field :system, :integer
    field :slot, :integer

    field :metal_units, :float
    field :crystal_units, :float
    field :deuterium_units, :float

    field :available_energy, :integer
    field :total_energy, :integer

    field :used_fields, :integer
    field :total_fields, :integer

    field :min_temperature, :integer
    field :max_temperature, :integer

    # image_id is used to refer to multiple planet images for the same planet type.
    field :image_id, :integer

    belongs_to :player, Galaxies.Accounts.Player, type: :binary_id

    has_many :buildings, Galaxies.PlanetBuilding
    has_many :units, Galaxies.PlanetUnit

    timestamps(type: :utc_datetime_usec)
  end

  def building_construction_complete_changeset(planet, attrs) do
    planet
    |> cast(attrs, [
      :used_fields,
      :total_fields,
      :metal_units,
      :crystal_units,
      :deuterium_units
    ])
  end

  def upgrade_building_changeset(planet, attrs) do
    planet
    |> cast(attrs, [
      :used_fields,
      :total_fields,
      :metal_units,
      :crystal_units,
      :deuterium_units
    ])
  end

  def upgrade_research_changeset(planet, attrs) do
    planet
    |> cast(attrs, [
      :metal_units,
      :crystal_units,
      :deuterium_units
    ])
  end

  def update_resource_count_changeset(planet, attrs) do
    planet
    |> cast(attrs, [
      :metal_units,
      :crystal_units,
      :deuterium_units
    ])
  end
end
