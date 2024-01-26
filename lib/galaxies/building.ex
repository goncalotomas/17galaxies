defmodule Galaxies.Building do
  use Galaxies.Schema

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
