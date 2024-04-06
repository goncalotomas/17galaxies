defmodule Galaxies.Research do
  @moduledoc """
  Defines the schema for the researches of the game.
  Uses integer IDs for simplicity.
  """

  use Ecto.Schema

  schema "researches" do
    field :name, :string

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
end
