defmodule Galaxies.Buildings do
  @moduledoc """
  Utility functions related to buildings, including building cost, duration and occupied fields.
  """

  # TODO: Maybe read hardcoded IDs from file or Application.compile_env?
  @terraformer_id "fe80d118-99fa-4792-8d27-1053d2960a94"

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

  def total_fields_increase(@terraformer_id, level, _demolish) do
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
