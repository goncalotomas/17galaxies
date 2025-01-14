defmodule Galaxies.Planets.PlanetEvent do
  @moduledoc """
  The schema for PlanetEventQueue.
  """
  alias Galaxies.Planets.Events.BuildingEvent
  use Galaxies.Schema

  import Ecto.Changeset

  @atom_values_mapping [
    # location events
    construction_complete: 10,
    research_complete: 11,
    unit_production_complete: 12,
    # fleet events
    fleet_attack: 20,
    fleet_collect: 21,
    fleet_colonize: 22,
    fleet_destroy: 23,
    fleet_recycle: 24,
    fleet_spy: 25,
    fleet_transport: 26,
    fleet_transfer: 27
  ]

  schema "planet_events" do
    # this type allows storing primary keys from multiple tables so that we can have
    # separate queues for buildings, research and shipyard construction.
    field :type, Ecto.Enum,
      values: @atom_values_mapping,
      null: false

    # for now only building events are supported
    embeds_one :building_event, Galaxies.Planets.Events.BuildingEvent

    field :started_at, :utc_datetime_usec
    # the completed_at field represents the moment in time when the event takes place,
    # not when it was processed by the server.
    field :completed_at, :utc_datetime_usec

    field :is_processed, :boolean, default: false
    field :is_cancelled, :boolean, default: false

    belongs_to :planet, Galaxies.Planet, type: :integer

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :type,
      :started_at,
      :completed_at,
      :is_processed,
      :is_cancelled,
      :planet_id
    ])
    |> cast_embed(:building_event, with: &BuildingEvent.changeset/2)
  end

  def get_fleet_event_ids do
    Enum.reduce(@atom_values_mapping, [], fn {event, id}, acc ->
      if id in 20..30 do
        [event | acc]
      else
        acc
      end
    end)
  end

  def process_changeset(event, attrs) do
    event
    |> cast(attrs, [:is_processed, :completed_at])
  end

  def update_changeset(event, attrs) do
    event
    |> cast(attrs, [:is_cancelled, :is_processed, :started_at, :completed_at])
  end
end
