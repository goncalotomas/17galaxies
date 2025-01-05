defmodule Galaxies.Planets.EnqueuedBuilding do
  @moduledoc """
  The schema for an enqueued building.
  Building queues are processed in order of insertion date.
  When an enqueued building is processed as completed, it is removed from the database.

  """
  use Galaxies.Schema

  import Ecto.Changeset

  schema "planet_build_queue" do
    field :list_order, :integer
    field :level, :integer
    field :demolish, :boolean, default: false

    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :building, Galaxies.Building, type: :integer
    belongs_to :planet, Galaxies.Planet, type: :integer

    timestamps(type: :utc_datetime_usec)
  end

  def advance_building_queue_changeset(enqueued_building, attrs) do
    enqueued_building
    |> cast(attrs, [:started_at, :completed_at])
  end
end
