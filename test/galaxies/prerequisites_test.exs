defmodule Galaxies.PrerequisitesTest do
  use Galaxies.DataCase, async: true

  alias Galaxies.Prerequisites
  alias Galaxies.Prerequisites.BuildingPrerequisiteBuilding
  alias Galaxies.Prerequisites.BuildingPrerequisiteResearch
  alias Galaxies.Prerequisites.ResearchPrerequisiteBuilding
  alias Galaxies.Prerequisites.ResearchPrerequisiteResearch
  alias Galaxies.Prerequisites.UnitPrerequisiteBuilding
  alias Galaxies.Prerequisites.UnitPrerequisiteResearch

  @metal_mine_building_id 1

  describe "get_building_prerequisites/1" do
    test "returns empty list for buildings without prerequisites" do
      assert [] == Prerequisites.get_building_prerequisites(@metal_mine_building_id)
    end

    test "every building prerequisite is listed" do
      for prereq <- Repo.all(BuildingPrerequisiteBuilding) do
        prerequisites = Prerequisites.get_building_prerequisites(prereq.building_id)

        assert {:building, prereq.prerequisite_building_id, prereq.prerequisite_building_level} in prerequisites
      end
    end

    test "every research prerequisite is listed" do
      for prereq <- Repo.all(BuildingPrerequisiteResearch) do
        prerequisites = Prerequisites.get_building_prerequisites(prereq.building_id)

        assert {:research, prereq.prerequisite_research_id, prereq.prerequisite_research_level} in prerequisites
      end
    end
  end

  describe "get_research_prerequisites/1" do
    test "every building prerequisite is listed" do
      for prereq <- Repo.all(ResearchPrerequisiteBuilding) do
        prerequisites = Prerequisites.get_research_prerequisites(prereq.research_id)

        assert {:building, prereq.prerequisite_building_id, prereq.prerequisite_building_level} in prerequisites
      end
    end

    test "every research prerequisite is listed" do
      for prereq <- Repo.all(ResearchPrerequisiteResearch) do
        prerequisites = Prerequisites.get_research_prerequisites(prereq.research_id)

        assert {:research, prereq.prerequisite_research_id, prereq.prerequisite_research_level} in prerequisites
      end
    end
  end

  describe "get_unit_prerequisites/1" do
    test "every building prerequisite is listed" do
      for prereq <- Repo.all(UnitPrerequisiteBuilding) do
        prerequisites = Prerequisites.get_unit_prerequisites(prereq.unit_id)

        assert {:building, prereq.prerequisite_building_id, prereq.prerequisite_building_level} in prerequisites
      end
    end

    test "every research prerequisite is listed" do
      for prereq <- Repo.all(UnitPrerequisiteResearch) do
        prerequisites = Prerequisites.get_unit_prerequisites(prereq.unit_id)

        assert {:research, prereq.prerequisite_research_id, prereq.prerequisite_research_level} in prerequisites
      end
    end
  end
end
