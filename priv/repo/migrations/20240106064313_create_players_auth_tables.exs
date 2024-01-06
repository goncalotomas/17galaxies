defmodule Galaxies.Repo.Migrations.CreatePlayersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:players) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps(type: :utc_datetime)
    end

    create unique_index(:players, [:email])

    create table(:players_tokens) do
      add :player_id, references(:players, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:players_tokens, [:player_id])
    create unique_index(:players_tokens, [:context, :token])
  end
end
