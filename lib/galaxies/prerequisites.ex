defmodule Galaxies.Prerequisites do
  @moduledoc """
  Application module responsible for managing the prerequisites of game entities
  such as units, buildings and researches.
  """

  require Logger
  alias Galaxies.Prerequisites.BuildingPrerequisiteBuilding
  alias Galaxies.Prerequisites.BuildingPrerequisiteResearch
  alias Galaxies.Prerequisites.ResearchPrerequisiteBuilding
  alias Galaxies.Prerequisites.ResearchPrerequisiteResearch
  alias Galaxies.Prerequisites.UnitPrerequisiteBuilding
  alias Galaxies.Prerequisites.UnitPrerequisiteResearch

  @doc """
  Loads all prerequisites from the database into memory.
  Prerequisite information is static and can be considered imutable,
  but this function can be called to reload prerequisites.
  """
  def load_static_prerequisites do
    building_prerequisite_buildings =
      Enum.reduce(
        Galaxies.Repo.all(BuildingPrerequisiteBuilding),
        %{},
        fn building_prereq, acc ->
          value =
            {:building, building_prereq.prerequisite_building_id,
             building_prereq.prerequisite_building_level}

          Map.update(
            acc,
            building_prereq.building_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    building_prerequisite_researches =
      Enum.reduce(
        Galaxies.Repo.all(BuildingPrerequisiteResearch),
        %{},
        fn building_prereq, acc ->
          value =
            {:research, building_prereq.prerequisite_research_id,
             building_prereq.prerequisite_research_level}

          Map.update(
            acc,
            building_prereq.building_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    building_prerequisites =
      Map.merge(
        building_prerequisite_buildings,
        building_prerequisite_researches,
        fn _building_id, prereqs_l, prereqs_r -> prereqs_l ++ prereqs_r end
      )

    research_prerequisite_buildings =
      Enum.reduce(
        Galaxies.Repo.all(ResearchPrerequisiteBuilding),
        %{},
        fn research_prereq, acc ->
          value =
            {:building, research_prereq.prerequisite_building_id,
             research_prereq.prerequisite_building_level}

          Map.update(
            acc,
            research_prereq.research_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    research_prerequisite_researches =
      Enum.reduce(
        Galaxies.Repo.all(ResearchPrerequisiteResearch),
        %{},
        fn research_prereq, acc ->
          value =
            {:research, research_prereq.prerequisite_research_id,
             research_prereq.prerequisite_research_level}

          Map.update(
            acc,
            research_prereq.research_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    research_prerequisites =
      Map.merge(
        research_prerequisite_buildings,
        research_prerequisite_researches,
        fn _research_id, prereqs_l, prereqs_r -> prereqs_l ++ prereqs_r end
      )

    unit_prerequisite_buildings =
      Enum.reduce(
        Galaxies.Repo.all(UnitPrerequisiteBuilding),
        %{},
        fn unit_prereq, acc ->
          value =
            {:building, unit_prereq.prerequisite_building_id,
             unit_prereq.prerequisite_building_level}

          Map.update(
            acc,
            unit_prereq.unit_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    unit_prerequisite_researches =
      Enum.reduce(
        Galaxies.Repo.all(UnitPrerequisiteResearch),
        %{},
        fn unit_prereq, acc ->
          value =
            {:research, unit_prereq.prerequisite_research_id,
             unit_prereq.prerequisite_research_level}

          Map.update(
            acc,
            unit_prereq.unit_id,
            [value],
            fn list -> [value | list] end
          )
        end
      )

    unit_prerequisites =
      Map.merge(
        unit_prerequisite_buildings,
        unit_prerequisite_researches,
        fn _research_id, prereqs_l, prereqs_r -> prereqs_l ++ prereqs_r end
      )

    Logger.info("Loaded prerequisites into memory")

    :persistent_term.put(:building_prerequisites, building_prerequisites)
    :persistent_term.put(:research_prerequisites, research_prerequisites)
    :persistent_term.put(:unit_prerequisites, unit_prerequisites)
    :ok
  end

  @doc """
  Fetches the list of prerequisites for a building.
  Each prerequisite has the form of {:building, :building_id, level} or {:research, :research_id, level}
  """
  @spec get_building_prerequisites(integer()) ::
          list({:building, integer(), integer()} | {:research, integer(), integer()})
  def get_building_prerequisites(building_id) do
    building_prereqs = :persistent_term.get(:building_prerequisites)
    Map.get(building_prereqs, building_id, [])
  end

  @doc """
  Fetches the list of prerequisites for a research.
  Each prerequisite has the form of {:building, :building_id, level} or {:research, :research_id, level}
  """
  @spec get_research_prerequisites(integer()) ::
          list({:building, integer(), integer()} | {:research, integer(), integer()})
  def get_research_prerequisites(research_id) do
    research_prereqs = :persistent_term.get(:research_prerequisites)
    Map.get(research_prereqs, research_id, [])
  end

  @doc """
  Fetches the list of prerequisites for a unit.
  Each prerequisite has the form of {:building, :building_id, level} or {:research, :research_id, level}
  """
  @spec get_unit_prerequisites(integer()) ::
          list({:building, integer(), integer()} | {:research, integer(), integer()})
  def get_unit_prerequisites(unit_id) do
    unit_prereqs = :persistent_term.get(:unit_prerequisites)
    Map.get(unit_prereqs, unit_id, [])
  end
end
