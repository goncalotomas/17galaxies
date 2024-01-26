defmodule GalaxiesWeb.OverviewLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_planet, Accounts.get_active_planet(socket.assigns.current_player))}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="flex border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <img
          class="h-32 w-32 mr-8 flex-none rounded bg-gray-50"
          src={"/images/planets/#{@current_planet.image_id}/large.webp"}
          alt={"Picture of #{@current_planet.name}"}
        />
        <div class="flex-auto">
          <h3 class="text-base font-semibold leading-6 text-gray-900">
            Overview — <%= @current_planet.name %>
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Temperature:</span>
            between <%= @current_planet.min_temperature %>°C and <%= @current_planet.max_temperature %>°C
          </p>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Diameter:</span> <%= @current_planet.total_fields * 54 %>km ( <%= @current_planet.used_fields %> / <%= @current_planet.total_fields %> fields )
          </p>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Coordinates:</span>
            [<%= @current_planet.galaxy %>:<%= @current_planet.system %>:<%= @current_planet.slot %>]
          </p>
        </div>
      </div>

      <%!-- <ul role="list" class="divide-y divide-gray-200">
        <li>
          <a href="#" class="block hover:bg-gray-50">
            <div class="px-4 py-4 sm:px-6">
              <div class="flex items-center justify-between">
                <div class="truncate text-sm font-medium text-indigo-600">Back End Developer</div>
                <div class="ml-2 flex flex-shrink-0">
                  <span class="inline-flex items-center rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                    Full-time
                  </span>
                </div>
              </div>
              <div class="mt-2 flex justify-between">
                <div class="sm:flex">
                  <div class="flex items-center text-sm text-gray-500">
                    <svg
                      class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M7 8a3 3 0 100-6 3 3 0 000 6zM14.5 9a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM1.615 16.428a1.224 1.224 0 01-.569-1.175 6.002 6.002 0 0111.908 0c.058.467-.172.92-.57 1.174A9.953 9.953 0 017 18a9.953 9.953 0 01-5.385-1.572zM14.5 16h-.106c.07-.297.088-.611.048-.933a7.47 7.47 0 00-1.588-3.755 4.502 4.502 0 015.874 2.636.818.818 0 01-.36.98A7.465 7.465 0 0114.5 16z">
                      </path>
                    </svg>
                    Engineering
                  </div>
                </div>
                <div class="ml-2 flex items-center text-sm text-gray-500">
                  <svg
                    class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M9.69 18.933l.003.001C9.89 19.02 10 19 10 19s.11.02.308-.066l.002-.001.006-.003.018-.008a5.741 5.741 0 00.281-.14c.186-.096.446-.24.757-.433.62-.384 1.445-.966 2.274-1.765C15.302 14.988 17 12.493 17 9A7 7 0 103 9c0 3.492 1.698 5.988 3.355 7.584a13.731 13.731 0 002.273 1.765 11.842 11.842 0 00.976.544l.062.029.018.008.006.003zM10 11.25a2.25 2.25 0 100-4.5 2.25 2.25 0 000 4.5z"
                      clip-rule="evenodd"
                    >
                    </path>
                  </svg>
                  Remote
                </div>
              </div>
            </div>
          </a>
        </li>
        <li>
          <a href="#" class="block hover:bg-gray-50">
            <div class="px-4 py-4 sm:px-6">
              <div class="flex items-center justify-between">
                <div class="truncate text-sm font-medium text-indigo-600">Front End Developer</div>
                <div class="ml-2 flex flex-shrink-0">
                  <span class="inline-flex items-center rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                    Full-time
                  </span>
                </div>
              </div>
              <div class="mt-2 flex justify-between">
                <div class="sm:flex">
                  <div class="flex items-center text-sm text-gray-500">
                    <svg
                      class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M7 8a3 3 0 100-6 3 3 0 000 6zM14.5 9a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM1.615 16.428a1.224 1.224 0 01-.569-1.175 6.002 6.002 0 0111.908 0c.058.467-.172.92-.57 1.174A9.953 9.953 0 017 18a9.953 9.953 0 01-5.385-1.572zM14.5 16h-.106c.07-.297.088-.611.048-.933a7.47 7.47 0 00-1.588-3.755 4.502 4.502 0 015.874 2.636.818.818 0 01-.36.98A7.465 7.465 0 0114.5 16z">
                      </path>
                    </svg>
                    Engineering
                  </div>
                </div>
                <div class="ml-2 flex items-center text-sm text-gray-500">
                  <svg
                    class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M9.69 18.933l.003.001C9.89 19.02 10 19 10 19s.11.02.308-.066l.002-.001.006-.003.018-.008a5.741 5.741 0 00.281-.14c.186-.096.446-.24.757-.433.62-.384 1.445-.966 2.274-1.765C15.302 14.988 17 12.493 17 9A7 7 0 103 9c0 3.492 1.698 5.988 3.355 7.584a13.731 13.731 0 002.273 1.765 11.842 11.842 0 00.976.544l.062.029.018.008.006.003zM10 11.25a2.25 2.25 0 100-4.5 2.25 2.25 0 000 4.5z"
                      clip-rule="evenodd"
                    >
                    </path>
                  </svg>
                  Remote
                </div>
              </div>
            </div>
          </a>
        </li>
        <li>
          <a href="#" class="block hover:bg-gray-50">
            <div class="px-4 py-4 sm:px-6">
              <div class="flex items-center justify-between">
                <div class="truncate text-sm font-medium text-indigo-600">
                  User Interface Designer
                </div>
                <div class="ml-2 flex flex-shrink-0">
                  <span class="inline-flex items-center rounded-full bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20">
                    Full-time
                  </span>
                </div>
              </div>
              <div class="mt-2 flex justify-between">
                <div class="sm:flex">
                  <div class="flex items-center text-sm text-gray-500">
                    <svg
                      class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M7 8a3 3 0 100-6 3 3 0 000 6zM14.5 9a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM1.615 16.428a1.224 1.224 0 01-.569-1.175 6.002 6.002 0 0111.908 0c.058.467-.172.92-.57 1.174A9.953 9.953 0 017 18a9.953 9.953 0 01-5.385-1.572zM14.5 16h-.106c.07-.297.088-.611.048-.933a7.47 7.47 0 00-1.588-3.755 4.502 4.502 0 015.874 2.636.818.818 0 01-.36.98A7.465 7.465 0 0114.5 16z">
                      </path>
                    </svg>
                    Design
                  </div>
                </div>
                <div class="ml-2 flex items-center text-sm text-gray-500">
                  <svg
                    class="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-400"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M9.69 18.933l.003.001C9.89 19.02 10 19 10 19s.11.02.308-.066l.002-.001.006-.003.018-.008a5.741 5.741 0 00.281-.14c.186-.096.446-.24.757-.433.62-.384 1.445-.966 2.274-1.765C15.302 14.988 17 12.493 17 9A7 7 0 103 9c0 3.492 1.698 5.988 3.355 7.584a13.731 13.731 0 002.273 1.765 11.842 11.842 0 00.976.544l.062.029.018.008.006.003zM10 11.25a2.25 2.25 0 100-4.5 2.25 2.25 0 000 4.5z"
                      clip-rule="evenodd"
                    >
                    </path>
                  </svg>
                  Remote
                </div>
              </div>
            </div>
          </a>
        </li>
      </ul> --%>
    </div>
    """
  end
end
