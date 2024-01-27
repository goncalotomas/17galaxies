defmodule Galaxies.Repo.Migrations.CreateResearchesTable do
  use Ecto.Migration

  def change do
    create table(:researches, primary_key: false) do
      add :id, :binary_id, primary_key: true
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

    create index(:researches, [:name])
    create index(:researches, [:name, :list_order])

    create table(:player_researches, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :research_id, references(:researches, type: :binary_id, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :current_level, :integer, default: 0
      add :is_upgrading, :boolean, default: false
      add :upgrade_finish_time, :utc_datetime

      timestamps(type: :utc_datetime_usec)
    end

    create index(:player_researches, [:player_id])
    create unique_index(:player_researches, [:player_id, :research_id])
  end
end
