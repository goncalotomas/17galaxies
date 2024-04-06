defmodule Galaxies.Prerequisites.BuildingPrerequisiteBuilding do
  @moduledoc """
  A Schema to represent the prerequisite buildings required to unlock a specific building.
  One example of this is that in order to build a Shipyard, you need a level 2 Robot Factory.
  This schema is used to represent building prerequisites on other buildings.
  """
  alias Galaxies.Building

  use Ecto.Schema

  schema "building_prerequisites_buildings" do
    belongs_to :building, Building, type: :integer
    belongs_to :prerequisite_building, Building, type: :integer
    field :prerequisite_building_level, :integer
  end
end
