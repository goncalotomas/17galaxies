defmodule GalaxiesWeb.GalaxyLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_planet, Accounts.get_active_planet(socket.assigns.current_player))
     |> assign(:current_system, Accounts.get_galaxy_view(1, 2))
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
          </div>
          <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
            <button
              type="button"
              class="block rounded-md bg-indigo-500 px-3 py-2 text-center text-sm font-semibold text-white hover:bg-indigo-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-500"
            >
              Add user
            </button>
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
                  <tr :for={slot <- 1..15}>
                    <td class="whitespace-nowrap py-1 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                      <%= slot %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= Enum.find(@current_system, %{}, fn planet -> planet.slot == slot end)
                      |> Map.get(:name) %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= Enum.find(@current_system, %{}, fn planet -> planet.slot == slot end)
                      |> Map.get(:player)
                      |> then(fn
                        nil -> nil
                        player -> player.username
                      end) %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= for action <- @actions do %>
                        <a href="#" class="text-indigo-400 hover:text-indigo-300">
                          <%= action %><span class="sr-only">, <%= slot %></span>
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
end
