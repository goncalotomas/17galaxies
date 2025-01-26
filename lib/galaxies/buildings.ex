defmodule Galaxies.Buildings do
  @moduledoc """
  Utility functions related to buildings, including building cost, duration and occupied fields.
  """

  # Maybe read hardcoded IDs from file or Application.compile_env?
  @resource_production_building_ids [1, 2, 3]
  @energy_production_building_ids [4, 5]
  @production_building_ids @resource_production_building_ids ++ @energy_production_building_ids
  @terraformer_building_id 13

  def production_building?(building_id) do
    building_id in @production_building_ids
  end

  def resource_production_building?(building_id) do
    building_id in @resource_production_building_ids
  end

  @doc """
  Determines the increase in used fields when upgrading a building.
  An upgrade will increase the number of used fields by 1 while a downgrade
  will decrease the number of used fields by 1
  """
  def used_fields_increase(_building_id, _level, true), do: -1
  def used_fields_increase(_building_id, _level, false), do: 1

  @doc """
  Determines the increase in total fields when upgrading a building.
  Some buildings, like the Terraformer or the Lunar base increase the number
  of total available fields
  """
  def total_fields_increase(_building_id, _level, true), do: 0

  def total_fields_increase(@terraformer_building_id, level, false) do
    if rem(level, 2) == 0 do
      6
    else
      5
    end
  end

  def total_fields_increase(_building_id, _level, _demolish) do
    0
  end
end
