defmodule Galaxies.Formulas.Buildings.Terraformer do
  @moduledoc """
  Formulas for the Terraformer building.
  """

  @doc """
  Returns the increase in fields when upgrading the Terraformer to a given level.
  The Terraformer cannot be
  """
  def field_increase(level) when level > 0 do
    trunc(Float.floor(5.5 * level) - Float.floor(5.5 * (level - 1)))
  end

  def total_fields(planet) do
    if planet.total_fields < 100 do
      1
    else
      0
    end
  end
end
