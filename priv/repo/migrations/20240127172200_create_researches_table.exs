defmodule Galaxies.Repo.Migrations.CreateResearchesTable do
  use Ecto.Migration

  def change do
    create table(:researches) do
      add :name, :string, null: false

      add :short_description, :text, null: false
      add :long_description, :text, null: false

      add :image_src, :string, null: false

      add :upgrade_time_formula, :string, null: false
      add :upgrade_cost_formula, :string, null: false
      add :production_formula, :string
      add :energy_consumption_formula, :string

      add :list_order, :smallint, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:researches, [:list_order])

    create table(:player_researches, primary_key: false) do
      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :research_id, references(:researches, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :level, :integer, default: 0
      add :is_upgrading, :boolean, default: false
      add :upgrade_finished_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:player_researches, [:player_id])
    create unique_index(:player_researches, [:player_id, :research_id])
  end
end
