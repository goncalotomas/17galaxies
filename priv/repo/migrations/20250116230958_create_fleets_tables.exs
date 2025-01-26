defmodule Galaxies.Repo.Migrations.CreateFleetsTables do
  use Ecto.Migration

  def change do
    create table(:fleets) do
      add :origin_planet_id, references(:planets), null: false

      add :destination_galaxy, :integer, null: false
      add :destination_system, :integer, null: false
      add :destination_slot, :integer, null: false
      add :destination_orbit, :integer, null: false

      add :cargo_metal_units, :integer, null: false
      add :cargo_crystal_units, :integer, null: false
      add :cargo_deuterium_units, :integer, null: false
      add :cargo_dark_matter_units, :integer, null: false
      add :cargo_artifacts, :map

      add :arriving_at, :utc_datetime_usec, null: false
      add :returning_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end
  end
end
