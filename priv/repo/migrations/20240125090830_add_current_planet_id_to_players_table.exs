defmodule Galaxies.Repo.Migrations.AddCurrentPlanetIdToPlayersTable do
  use Ecto.Migration

  @moduledoc """
  The players table has a cyclic dependency on the planets table.
  All planets reference a specific player, but we also need to store information about
  the currently active player. We can solve this by adding a deferrable constraint that
  allows us to store a planet ID that doesn't exist as the player's active player, which
  is verified as correct upon transaction commit.

  This type of constraint wasn't possible to add using Ecto.Migration so we had to use an
  `execute` statement.
  """

  def change do
    execute """
    ALTER TABLE players
    ADD COLUMN current_planet_id serial
    CONSTRAINT players_current_planet_id_fk
    REFERENCES planets (id)
    DEFERRABLE INITIALLY DEFERRED;
    """

    create index(:players, [:current_planet_id])
  end
end
