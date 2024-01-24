defmodule Galaxies.Planet do
  use Galaxies.Schema

  schema "planets" do
    field :name, :string
    # planets are identified by a set of coordinates
    # {galaxy, system, slot}
    field :galaxy, :integer
    field :system, :integer
    field :slot, :integer
    # planet resources
    field :metal_units, :integer
    field :crystal_units, :integer
    field :deuterium_units, :integer
    # resource growth rate is a column of planets as an optimization.
    # this avoids requiring to fetch the planet buildings in order to
    # increment resources from the frontend.
    field :metal_growth_rate, :float
    field :crystal_growth_rate, :float
    field :deuterium_growth_rate, :float

    timestamps(type: :utc_datetime)

    belongs_to :player, Galaxies.Accounts.Player
  end
end
