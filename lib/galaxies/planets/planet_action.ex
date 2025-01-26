defmodule Galaxies.Planets.PlanetAction do
  use Ecto.Schema

  @types [
    :enqueue_building,
    :enqueue_research,
    :enqueue_unit
  ]

  embedded_schema do
    field :type, Ecto.Enum, values: @types
    field :data, :map
    belongs_to :planet, Galaxies.Planet
  end
end
