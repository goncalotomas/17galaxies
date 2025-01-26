defmodule Galaxies.Building do
  @moduledoc """
  Defines the schema for the buildings of the game.
  Uses integer IDs for simplicity.
  """

  use Ecto.Schema

  schema "buildings" do
    field :name, :string

    field :type, Ecto.Enum, values: [resource: 1, facility: 2], null: false

    field :short_description, :string
    field :long_description, :string

    field :image_src, :string

    field :upgrade_cost_formula, :string

    field :list_order, :integer

    timestamps(type: :utc_datetime)
  end

  def terraformer_extra_fields(level) when rem(level, 2) == 0, do: 6
  def terraformer_extra_fields(_level), do: 5
end
