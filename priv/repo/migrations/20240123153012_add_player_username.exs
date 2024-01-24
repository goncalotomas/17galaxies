defmodule Galaxies.Repo.Migrations.AddPlayerUsername do
  use Ecto.Migration

  def change do
    alter table("players") do
      add :username, :string, null: false
    end

    create unique_index("players", [:username])
  end
end
