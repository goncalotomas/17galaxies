defmodule GalaxiesWeb.Common do
  alias Galaxies.Accounts
  alias Phoenix.PubSub

  @doc """
  Performs a set of operations common to most navigatable routes of the game.
  """
  def mount_live_context(socket) do
    player = Galaxies.Repo.preload(socket.assigns.current_player, [:planets])
    fleet_events = Accounts.get_fleet_events(player.id)

    for planet <- player.planets do
      PubSub.subscribe(Galaxies.PubSub, "planets:#{planet.id}")
    end

    socket
    |> Phoenix.Component.assign(:current_player, player)
    |> Phoenix.Component.assign(
      :current_planet,
      Enum.find(player.planets, &(&1.id == player.current_planet_id))
    )
    |> Phoenix.Component.assign(:fleet_events, fleet_events)
  end
end
