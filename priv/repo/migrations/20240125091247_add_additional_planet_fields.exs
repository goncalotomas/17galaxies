defmodule Galaxies.Repo.Migrations.AddAdditionalPlanetFields do
  use Ecto.Migration

  def change do
    alter table("planets") do
      add :min_temperature, :integer, null: false
      add :max_temperature, :integer, null: false

      add :total_energy, :integer, default: 0
      add :available_energy, :integer, default: 0

      add :total_fields, :integer, default: 250
      add :used_fields, :integer, default: 0

      add :image_id, :integer, null: false
    end
  end
end
