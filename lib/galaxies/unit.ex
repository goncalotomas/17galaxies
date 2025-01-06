defmodule Galaxies.Unit do
  @moduledoc """
  Defines the schema for the unit of the game.
  Uses integer IDs for simplicity.
  """

  use Ecto.Schema

  schema "units" do
    field :name, :string

    field :type, Ecto.Enum, values: [ship: 1, defense: 2, planet_ship: 3, missile: 4], null: false

    field :short_description, :string
    field :long_description, :string

    field :image_src, :string

    field :unit_cost_metal, :integer
    field :unit_cost_crystal, :integer
    field :unit_cost_deuterium, :integer
    field :unit_cost_energy, :integer, default: 0

    field :weapon_points, :integer
    field :shield_points, :integer
    field :hull_points, :integer

    field :speed, :integer
    field :deuterium_consumption, :integer

    field :list_order, :integer

    timestamps(type: :utc_datetime_usec)
  end
end
