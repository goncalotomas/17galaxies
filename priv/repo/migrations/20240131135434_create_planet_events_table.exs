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
      add :type, :integer, null: false
      # event data is polymorphic and depends on event type
      add :data, :map
      add :event_id, :binary_id, null: false

      # precision of seconds is on purpose to enable multiple events to have the same timestamp
      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    create index(:planet_events, [:planet_id, :completed_at])

    create table(:planet_build_queue, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :planet_id, references(:planets, type: :binary_id, on_delete: :delete_all), null: false

      add :building_id, references(:buildings, type: :binary_id, on_delete: :delete_all),
        null: false

      add :level, :integer, null: false
      add :list_order, :integer, null: false
      add :demolish, :boolean, default: false

      add :started_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec

      # inserted_at timestamp sets total order of events inside planet so queries will sort by this field
      timestamps(type: :utc_datetime_usec)
    end

    execute(
      "CREATE INDEX planet_events_data ON planet_events USING GIN(data)",
      "DROP INDEX planet_events_data"
    )
  end
end
