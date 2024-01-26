defmodule Galaxies.Building do
  @moduledoc """
  Defines the schema for the buildings of the game. We use Ecto.Schema instead
  of Galaxies.Schema because we want integer IDs and not UUIDs as the primary
  key. The reason for this is that we want the return order for buildings to be
  deterministic, and that doesn't happen with standard UUIDv4s.
  """

  use Ecto.Schema

  schema "buildings" do
    field :name, :string

    field :short_description, :string
    field :long_description, :string

    field :image_src, :string

    field :upgrade_time_formula, :string
    field :upgrade_cost_formula, :string
    field :production_formula, :string
    field :energy_consumption_formula, :string

    timestamps(type: :utc_datetime_usec)
  end
end
