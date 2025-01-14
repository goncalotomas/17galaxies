defmodule Galaxies.Repo.Migrations.CreateEventQueueTables do
  @moduledoc """
  Defines an event queue to serialize all events happening on any given planet.
  When wanting to move time forward for a given planet, the game can read from
  the planet event queue and execute all events in order. Processing the events
  for one planet does not affect any other events.
  Keep in mind that player actions may cause events in the queue to be
  cancelled (e.g. cancelling an attack) or postponed (sending more ships to an
  union attacking a planet).
  """
  use Ecto.Migration

  def change do
    create table(:planet_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :planet_id, references(:planets, type: :serial, on_delete: :delete_all), null: false
      # specifies which embed to search
      add :type, :integer, null: false

      # only one of these will be set
      add :building_event, :map, null: true
      add :research_event, :map, null: true
      add :fleet_event, :map, null: true

      add :started_at, :utc_datetime_usec, null: true
      # completed_at represents the time when the event takes place,
      # not when it was processed. It is nil when an event is supposed to be processed
      # after a previous event (e.g. building queue, research queue, etc)
      add :completed_at, :utc_datetime_usec, null: true

      add :is_processed, :boolean, default: false, null: false
      add :is_cancelled, :boolean, default: false, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:planet_events, [:planet_id, :completed_at])
    create index(:planet_events, [:planet_id, :inserted_at])
  end
end
