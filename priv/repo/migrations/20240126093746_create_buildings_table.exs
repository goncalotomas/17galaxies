defmodule Galaxies.Repo.Migrations.CreateBuildingsTable do
  use Ecto.Migration

  def change do
    create table(:buildings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false

      add :short_description, :text, null: false
      add :long_description, :text, null: false

      add :image_src, :string, null: false

      add :upgrade_time_formula, :string
      add :upgrade_cost_formula, :string, null: false
      add :production_formula, :string
      add :energy_consumption_formula, :string

      add :list_order, :smallint, null: false

      add :type, :smallint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:buildings, [:name])
    create index(:buildings, [:name, :list_order])

    create table(:planet_buildings, primary_key: false) do
      add :planet_id, references(:planets, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :building_id, references(:buildings, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :current_level, :integer, default: 0
      add :is_upgrading, :boolean, default: false
      add :upgrade_finish_time, :utc_datetime

      timestamps(type: :utc_datetime_usec)
    end

    create index(:planet_buildings, [:planet_id])
    create unique_index(:planet_buildings, [:planet_id, :building_id])
  end
end
