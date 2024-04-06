defmodule Galaxies.Prerequisites.BuildingPrerequisiteResearch do
  @moduledoc """
  A Schema to represent the prerequisite researches required to unlock a specific building.
  One example of this is that in order to build a Nanite Factory, you need a level 10 Computer Tech.
  This schema is used to represent research prerequisites for buildings.
  """
  alias Galaxies.Building
  alias Galaxies.Research

  use Ecto.Schema

  schema "building_prerequisites_researches" do
    belongs_to :building, Building, type: :integer
    belongs_to :prerequisite_research, Research, type: :integer
    field :prerequisite_research_level, :integer
  end
end
