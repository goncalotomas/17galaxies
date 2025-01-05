defmodule Galaxies.PlanetUnit do
  use Galaxies.Schema

  @primary_key false
  schema "planet_units" do
    field :amount, :integer

    belongs_to :planet, Galaxies.Planet, primary_key: true, type: :integer
    belongs_to :unit, Galaxies.Unit, primary_key: true, type: :integer

    timestamps(type: :utc_datetime_usec)
  end
end
