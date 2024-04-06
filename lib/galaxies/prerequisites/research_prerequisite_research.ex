defmodule Galaxies.Prerequisites.ResearchPrerequisiteResearch do
  @moduledoc """
  A Schema to represent the prerequisite researches required to unlock a specific research.
  One example of this is that in order to research Astrophysics,
  you need a) level 4 Espionage Tech and b) level 3 Impulse Drive
  This schema is used to represent research prerequisites for other researches.
  """
  alias Galaxies.Research

  use Ecto.Schema

  schema "research_prerequisites_researches" do
    belongs_to :research, Research, type: :integer
    belongs_to :prerequisite_research, Research, type: :integer
    field :prerequisite_research_level, :integer
  end
end
