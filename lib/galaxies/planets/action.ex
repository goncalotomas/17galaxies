defmodule Galaxies.Planets.Action do
  @moduledoc """
  An action is a command that a player performs on a planet that is processed immediately.
  """

  @callback perform(%Galaxies.Accounts.Player{}, %Galaxies.Planets.PlanetAction{}) ::
              {:ok, map()} | {:error, map()}
end
