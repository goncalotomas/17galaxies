defmodule GalaxiesWeb.FleetLive do
  use Phoenix.LiveView

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_planet, Accounts.get_active_planet(socket.assigns.current_player))}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Fleet — <%= @current_planet.name %>
        </h3>
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={ship <- Accounts.get_planet_ship_units(@current_planet)}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600"><%= ship.name %></div>
            </div>
            <div class="mt-2 flex justify-between">
              <div class="sm:flex">
                <div class="flex items-center text-sm text-gray-500">
                  <img
                    class="h-32 w-32 mr-8 flex-none rounded bg-gray-50"
                    src="/images/planets/1/large.webp"
                  />
                  <%= ship.description_short %>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-gray-500">
                <a href="#" class="block hover:bg-gray-50">
                  Upgrade
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke-width="1.5"
                    stroke="currentColor"
                    class="w-6 h-6"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="m4.5 15.75 7.5-7.5 7.5 7.5"
                    />
                  </svg>
                </a>
              </div>
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end
end
