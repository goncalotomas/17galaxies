defmodule GalaxiesWeb.OverviewLive do
  use GalaxiesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, GalaxiesWeb.Common.mount_live_context(socket)}
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
            Overview — {@current_planet.name}
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Temperature:</span>
            between {@current_planet.min_temperature}°C and {@current_planet.max_temperature}°C
          </p>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Diameter:</span> {@current_planet.total_fields * 54}km ( {@current_planet.used_fields} / {@current_planet.total_fields} fields )
          </p>
          <p class="mt-1 text-sm text-gray-500">
            <span class="text-gray-800">Coordinates:</span>
            [{@current_planet.galaxy}:{@current_planet.system}:{@current_planet.slot}]
          </p>
        </div>
      </div>
    </div>
    """
  end
end
