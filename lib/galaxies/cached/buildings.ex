defmodule Galaxies.Cached.Buildings do
  @moduledoc """
  A local copy of all the game's buildings, which are considered immutable.
  """
  alias Galaxies.Repo
  require Logger

  @cache_name :galaxies_buildings

  def load_static_buildings do
    started_at = DateTime.utc_now(:millisecond)

    for building <- Repo.all(Galaxies.Building) do
      :persistent_term.put({@cache_name, building.id}, building)
    end

    Logger.info(
      "Loaded static buildings in #{DateTime.diff(DateTime.utc_now(:millisecond), started_at, :millisecond)}ms"
    )
  end

  def get_building_by_id(building_id) do
    :persistent_term.get({@cache_name, building_id})
  end
end
