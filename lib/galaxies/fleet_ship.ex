defmodule Galaxies.FleetShip do
  use Galaxies.Schema

  schema "fleet_ships" do
    belongs_to :fleet, Galaxies.FleetInMotion
    belongs_to :ship, Galaxies.Unit

    field :amount, :integer
  end
end
