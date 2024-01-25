defmodule Galaxies.Planet do
  use Galaxies.Schema

  schema "planets" do
    field :name, :string

    # planets are identified by a set of coordinates {galaxy, system, slot}
    field :galaxy, :integer
    field :system, :integer
    field :slot, :integer

    field :metal_units, :integer
    field :crystal_units, :integer
    field :deuterium_units, :integer

    field :available_energy, :integer
    field :total_energy, :integer

    field :used_fields, :integer
    field :total_fields, :integer

    field :min_temperature, :integer
    field :max_temperature, :integer

    # resource growth rate is an optimization that avoids calculating the growth rate
    # from building levels just to update the resource count periodically.
    field :metal_growth_rate, :decimal
    field :crystal_growth_rate, :decimal
    field :deuterium_growth_rate, :decimal

    # image_id is used to refer to multiple planet images for the same planet type.
    field :image_id, :integer

    timestamps(type: :utc_datetime)

    belongs_to :player, Galaxies.Accounts.Player
  end
end
