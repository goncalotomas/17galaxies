defmodule GalaxiesWeb.GalaxyLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts
  alias Galaxies.Planet
  alias Galaxies.Accounts.Player

  def mount(_params, _session, socket) do
    socket = GalaxiesWeb.Common.mount_live_context(socket)

    current_system =
      Accounts.get_galaxy_view(
        socket.assigns.current_planet.galaxy,
        socket.assigns.current_planet.system
      )

    slots =
      Enum.reduce(1..15, [], fn slot, acc ->
        planet = Enum.find(current_system, fn planet -> planet.slot == slot end)

        current_slot =
          if planet do
            {slot, planet, planet.player, possible_actions(socket.assigns.current_player, planet)}
          else
            {slot, nil, nil, [action(:colonize)]}
          end

        acc ++ [current_slot]
      end)

    {:ok,
     socket
     |> assign(:slots, slots)
     |> assign(:actions, [
       "Spy",
       "Attack",
       "Transport",
       "Recycle",
       "Colonize"
     ])}
  end

  def render(assigns) do
    ~H"""
    <div class="rounded-md bg-slate-950 py-4">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-base font-semibold leading-6 text-white">
              Galaxy — <%= @current_planet.name %>
            </h1>
            <h5>
              Galaxy <%= @current_planet.galaxy %>, Solar System no. <%= @current_planet.system %>
            </h5>
          </div>
        </div>
        <div class="mt-8 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-700">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0"
                    >
                      Planet
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Name
                    </th>
                    <%!-- <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                          Moon
                        </th> --%>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Player
                    </th>
                    <%!-- <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                          Alliance
                        </th> --%>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Actions
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span class="sr-only">Edit</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-800">
                  <tr :for={{slot, planet, player, actions} <- @slots}>
                    <td class="whitespace-nowrap py-1 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                      <%= slot %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= if planet do %>
                        <%= planet.name %>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= if player do %>
                        <%= player.username %>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= for action <- actions do %>
                        <a href="#" class="text-indigo-400 hover:text-indigo-300 text-xs px-1">
                          <%!-- <.icon name="hero-globe-alt" /> --%>
                          <.icon name={action.icon_name} />
                          <%= action.name %>
                        </a>
                      <% end %>
                    </td>
                    <%!-- <td class="relative whitespace-nowrap py-1 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">

                        </td> --%>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp possible_actions(%Player{id: id, current_planet_id: planet_id}, %Planet{
         id: planet_id,
         player: %Player{id: id}
       }) do
    # planet is the currently active planet.
    []
  end

  defp possible_actions(%Player{id: id}, %Planet{player: %Player{id: id}}) do
    # other planet from the same player
    [action(:transport)]
  end

  defp possible_actions(_player, _planet) do
    # other planet from another player
    [action(:spy), action(:attack), action(:transport)]
  end

  defp action(:transport) do
    %{
      icon_name: "hero-banknotes",
      name: "Transport"
    }
  end

  defp action(:attack) do
    %{
      icon_name: "hero-viewfinder-circle",
      name: "Attack"
    }
  end

  defp action(:spy) do
    %{
      icon_name: "hero-eye",
      name: "Spy"
    }
  end

  defp action(:colonize) do
    %{
      icon_name: "hero-globe-alt",
      name: "Colonize"
    }
  end
end
