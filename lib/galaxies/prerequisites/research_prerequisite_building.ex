defmodule Galaxies.Prerequisites.ResearchPrerequisiteBuilding do
  @moduledoc """
  A Schema to represent the prerequisite buildings required to unlock a specific research.
  One example of this is that in order to build Weapons Tech, you need a level 4 Research Lab.
  This schema is used to represent building prerequisites for researches.
  """
  alias Galaxies.Research
  alias Galaxies.Building

  use Ecto.Schema

  schema "research_prerequisites_buildings" do
    belongs_to :research, Research, type: :integer
    belongs_to :prerequisite_building, Building, type: :integer
    field :prerequisite_building_level, :integer
  end
end
