defmodule Galaxies.Repo.Migrations.AddPlayerPlanets do
  use Ecto.Migration

  def change do
    create table(:planets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 24, null: false

      add :galaxy, :smallint, null: false
      add :system, :smallint, null: false
      add :slot, :smallint, null: false

      add :metal_units, :bigint, default: 0
      add :crystal_units, :bigint, default: 0
      add :deuterium_units, :bigint, default: 0

      add :metal_growth_rate, :numeric, default: 0.0
      add :crystal_growth_rate, :numeric, default: 0.0
      add :deuterium_growth_rate, :numeric, default: 0.0

      add :min_temperature, :integer, null: false
      add :max_temperature, :integer, null: false

      add :total_energy, :integer, default: 0
      add :available_energy, :integer, default: 0

      add :total_fields, :integer, default: 250
      add :used_fields, :integer, default: 0

      add :image_id, :integer, null: false

      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:planets, [:player_id])
    create index(:planets, [:galaxy, :system])
    create unique_index(:planets, [:galaxy, :system, :slot])
  end
end
