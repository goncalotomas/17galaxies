defmodule Galaxies.PlanetFixtures do
  alias Galaxies.Repo
  import Ecto.Changeset

  def planet_fixture(attrs \\ %{}) do
    {:ok, %{planet: planet}} =
      Galaxies.AccountsFixtures.valid_player_attributes()
      |> Galaxies.Accounts.register_player()

    planet =
      planet
      |> change(attrs)
      |> Repo.update!()

    planet
  end
end
