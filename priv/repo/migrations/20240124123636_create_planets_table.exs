defmodule Galaxies.Repo.Migrations.CreatePlanetsTable do
  use Ecto.Migration

  def change do
    create table(:planets, primary_key: false) do
      add :id, :serial, primary_key: true
      add :name, :string, size: 24, null: false

      add :galaxy, :smallint, null: false
      add :system, :smallint, null: false
      add :slot, :smallint, null: false

      add :metal_units, :float, default: 0.0, null: false
      add :crystal_units, :float, default: 0.0, null: false
      add :deuterium_units, :float, default: 0.0, null: false

      add :min_temperature, :integer, null: false
      add :max_temperature, :integer, null: false

      add :total_energy, :integer, default: 0
      add :available_energy, :integer, default: 0

      add :total_fields, :integer, default: 250
      add :used_fields, :integer, default: 0

      add :image_id, :integer, null: false

      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:planets, [:player_id])
    create index(:planets, [:galaxy, :system])
    create unique_index(:planets, [:galaxy, :system, :slot])

    create constraint(:planets, :metal_units_must_be_non_negative, check: "metal_units >= 0")
    create constraint(:planets, :crystal_units_must_be_non_negative, check: "crystal_units >= 0")

    create constraint(:planets, :deuterium_units_must_be_non_negative,
             check: "deuterium_units >= 0"
           )
  end
end
