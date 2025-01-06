defmodule GalaxiesWeb.DefensesLive do
  use GalaxiesWeb, :live_view
  import GalaxiesWeb.CommonComponents

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    socket = GalaxiesWeb.Common.mount_live_context(socket)
    planet_defenses = Accounts.get_planet_defense_units(socket.assigns.current_planet)

    {:ok, assign(socket, :planet_defenses, planet_defenses)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Defenses — {@current_planet.name}
        </h3>
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={defense <- @planet_defenses}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600">{defense.name}</div>
            </div>
            <div class="mt-2 flex justify-between">
              <div class="sm:flex">
                <div class="flex items-center text-sm text-gray-500">
                  <!-- we need the object-fit style to adapt any rectangular images into square ones -->
                  <img
                    class="h-32 w-32 mr-8 flex-none rounded bg-gray-50"
                    style="object-fit: cover;"
                    src={defense.image_src}
                  />
                  <p>
                    {defense.description_short}<br />
                    <.unit_cost
                      metal={defense.unit_cost_metal}
                      crystal={defense.unit_cost_crystal}
                      deuterium={defense.unit_cost_deuterium}
                      energy={defense.unit_cost_energy}
                    />
                  </p>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-gray-500">
                <a href="#" class="block hover:bg-gray-50">
                  Produce
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
