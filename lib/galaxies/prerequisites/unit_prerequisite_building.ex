defmodule Galaxies.Prerequisites.UnitPrerequisiteBuilding do
  @moduledoc """
  A Schema to represent the prerequisite buildings required to unlock a specific unit.
  One example of this is that in order to build Cruisers, you need a level 5 Shipyard.
  This schema is used to represent building prerequisites for units.
  """
  alias Galaxies.Unit
  alias Galaxies.Building

  use Ecto.Schema

  schema "unit_prerequisites_buildings" do
    belongs_to :unit, Unit, type: :integer
    belongs_to :prerequisite_building, Building, type: :integer
    field :prerequisite_building_level, :integer
  end
end
