defmodule Galaxies.Building do
  @moduledoc """
  Defines the schema for the buildings of the game.
  """

  use Galaxies.Schema

  schema "buildings" do
    field :name, :string

    field :type, Ecto.Enum, values: [resource: 1, facility: 2], null: false

    field :short_description, :string
    field :long_description, :string

    field :image_src, :string

    field :upgrade_time_formula, :string
    field :upgrade_cost_formula, :string
    field :production_formula, :string
    field :energy_consumption_formula, :string

    field :list_order, :integer

    timestamps(type: :utc_datetime_usec)
  end

  def terraformer_extra_fields(level) when rem(level, 2) == 0, do: 6
  def terraformer_extra_fields(_level), do: 5
end
