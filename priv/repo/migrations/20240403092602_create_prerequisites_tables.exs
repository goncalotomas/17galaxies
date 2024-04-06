defmodule Galaxies.Repo.Migrations.CreatePrerequisitesTables do
  @moduledoc """
  Creates the required tables for supporting prerequisites.
  The ability to build instances of the main entities of the game (building, research, unit)
  may depend on the level of buildings on the current planet or on the level of player researches.
  The tables created in this
  """
  use Ecto.Migration

  def change do
    create table(:building_prerequisites_buildings) do
      add :building_id, references(:buildings), null: false
      add :prerequisite_building_id, references(:buildings), null: false
      add :prerequisite_building_level, :integer, null: false
    end

    create table(:building_prerequisites_researches) do
      add :building_id, references(:buildings), null: false
      add :prerequisite_research_id, references(:researches), null: false
      add :prerequisite_research_level, :integer, null: false
    end

    create table(:research_prerequisites_buildings) do
      add :research_id, references(:researches), null: false
      add :prerequisite_building_id, references(:buildings), null: false
      add :prerequisite_building_level, :integer, null: false
    end

    create table(:research_prerequisites_researches) do
      add :research_id, references(:researches), null: false
      add :prerequisite_research_id, references(:researches), null: false
      add :prerequisite_research_level, :integer, null: false
    end

    create table(:unit_prerequisites_buildings) do
      add :unit_id, references(:units), null: false
      add :prerequisite_building_id, references(:buildings), null: false
      add :prerequisite_building_level, :integer, null: false
    end

    create table(:unit_prerequisites_researches) do
      add :unit_id, references(:units), null: false
      add :prerequisite_research_id, references(:researches), null: false
      add :prerequisite_research_level, :integer, null: false
    end

    create unique_index(:building_prerequisites_buildings, [
             :building_id,
             :prerequisite_building_id
           ])

    create unique_index(:building_prerequisites_researches, [
             :building_id,
             :prerequisite_research_id
           ])

    create unique_index(:research_prerequisites_buildings, [
             :research_id,
             :prerequisite_building_id
           ])

    create unique_index(:research_prerequisites_researches, [
             :research_id,
             :prerequisite_research_id
           ])

    create unique_index(:unit_prerequisites_buildings, [:unit_id, :prerequisite_building_id])
    create unique_index(:unit_prerequisites_researches, [:unit_id, :prerequisite_research_id])
  end
end
