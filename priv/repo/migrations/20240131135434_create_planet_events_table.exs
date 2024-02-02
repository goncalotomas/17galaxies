defmodule Galaxies.Repo.Migrations.CreateEventQueueTables do
  @moduledoc """
  Defines an event queue to serialize all events happening on any given planet.
  When wanting to move time forward for a given planet, the game can read from
  the planet event queue and execute all events by order. Processing the events
  for one planet does not affect any other events.
  Keep in mind that player actions may cause events in the queue to be
  cancelled (e.g. cancelling an attack) or postponed (sending more ships to an
  union attacking a planet).
  """
  use Ecto.Migration

  def change do
    create table(:planet_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :planet_id, references(:planets, type: :binary_id, on_delete: :delete_all), null: false
      # specifies which table to fetch event from (e.g. planet_building_queue, fleet, etc).
      add :type, :integer
      # event data is polymorphic and depends on event type
      add :data, :map, null: false

      # precision of seconds is on purpose to enable multiple events to have the same timestamp
      add :completed_at, :utc_datetime
    end

    create index(:planet_events, [:planet_id, :completed_at])

    execute(
      "CREATE INDEX planet_events_data ON planet_events USING GIN(data)",
      "DROP INDEX planet_events_data"
    )
  end
end
