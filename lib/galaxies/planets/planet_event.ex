defmodule Galaxies.Planets.PlanetEvent do
  @moduledoc """
  The schema for PlanetEventQueue.
  """
  use Galaxies.Schema

  @atom_values_mapping [
    # location events
    building_construction: 10,
    technology_research_complete: 11,
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

    field :event_id, :binary_id
    field :data, :map

    field :completed_at, :utc_datetime

    belongs_to :planet, Galaxies.Planet, type: :integer

    timestamps(updated_at: false, type: :utc_datetime)
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
end
