defmodule Galaxies.Fleet do
  use Galaxies.Schema

  @moduledoc """
  A fleet in group of ships (units) traveling to a destination.
  A fleet always originates from an existing planet, but multiple mission types
  allow for destinations which are not planets (e.g. exploration, colonization).
  """

  @orbits [planet: 1, moon: 2, debris_field: 3]

  schema "fleets" do
    field :destination_galaxy, :integer
    field :destination_system, :integer
    field :destination_slot, :integer
    field :destination_orbit, Ecto.Enum, values: @orbits

    field :cargo_metal_units, :integer
    field :cargo_crystal_units, :integer
    field :cargo_deuterium_units, :integer
    field :cargo_dark_matter_units, :integer
    field :cargo_artifacts, :map

    field :arriving_at, :utc_datetime_usec
    field :returning_at, :utc_datetime_usec

    belongs_to :origin_planet, Galaxies.Planet

    has_many :fleet_ships, Galaxies.FleetShip

    timestamps(type: :utc_datetime_usec)
  end
end
