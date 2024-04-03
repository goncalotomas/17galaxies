defmodule Galaxies.Repo.Migrations.CreateUnitsTable do
  use Ecto.Migration

  def change do
    create table(:units) do
      add :name, :string, null: false

      add :short_description, :text, null: false
      add :long_description, :text, null: false

      add :image_src, :string, null: false

      add :unit_cost_metal, :integer
      add :unit_cost_crystal, :integer
      add :unit_cost_deuterium, :integer

      add :weapon_points, :integer
      add :shield_points, :integer
      add :hull_points, :integer

      add :speed, :integer
      add :deuterium_consumption, :integer

      add :list_order, :smallint, null: false

      add :type, :smallint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:units, [:name])
    create index(:units, [:name, :list_order])

    create table(:planet_units, primary_key: false) do
      add :planet_id, references(:planets, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :unit_id, references(:units, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :amount, :integer, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:planet_units, [:planet_id])
    create unique_index(:planet_units, [:planet_id, :unit_id])

    create constraint(:planet_units, :planet_unit_amounts_must_be_non_negative,
             check: "amount >= 0"
           )
  end
end
