defmodule GalaxiesWeb.Components.PlanetResources do
  use GalaxiesWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%!-- swap md:grid-cols-4 for md:grid-cols-5 when adding dark matter --%>
      <dl class="mt-5 grid grid-cols-1 divide-y divide-gray-200 overflow-hidden rounded-lg bg-white shadow md:grid-cols-4 md:divide-y-0 md:divide-x">
        <div class="px-2 py-2 sm:p-6">
          <dt class="text-base font-normal text-gray-900">Metal</dt>
          <dd class="mt-1">
            <div class="text-2xl font-semibold text-indigo-600">
              <%= pretty_print(@planet.metal_units) %>
            </div>
          </dd>
        </div>

        <div class="px-4 py-5 sm:p-6">
          <dt class="text-base font-normal text-gray-900">Crystal</dt>
          <dd class="mt-1">
            <div class="text-2xl font-semibold text-indigo-600">
              <%= pretty_print(@planet.crystal_units) %>
            </div>
          </dd>
        </div>
        <div class="px-4 py-5 sm:p-6">
          <dt class="text-base font-normal text-gray-900">Deuterium</dt>
          <dd class="mt-1">
            <div class="text-2xl font-semibold text-indigo-600">
              <%= pretty_print(@planet.deuterium_units) %>
            </div>
          </dd>
        </div>
        <div class="px-4 py-5 sm:p-6">
          <dt class="text-base font-normal text-gray-900">Energy</dt>
          <dd class="mt-1">
            <div class="text-2xl font-semibold text-indigo-600">
              <%= pretty_print(@planet.available_energy) %>
            </div>
          </dd>
        </div>

        <%!-- <div class="px-4 py-5 sm:p-6">
          <dt class="text-base font-normal text-gray-900">Dark Matter</dt>
          <dd class="mt-1">
            <div class="text-2xl font-semibold text-indigo-600">
              71,897
            </div>
          </dd>
        </div> --%>
      </dl>
    </div>
    """
  end

  # defp pretty_print(number), do: "#{trunc(number)}"
  defp pretty_print(number) when number < 100_000, do: "#{trunc(number)}"
  defp pretty_print(number) when number < 1_000_000, do: "#{Float.floor(number / 1_000, 2)}K"

  defp pretty_print(number) when number < 1_000_000_000,
    do: "#{Float.floor(number / 1_000_000, 2)}M"

  defp pretty_print(number) when number < 1_000_000_000_000,
    do: "#{Float.floor(number / 1_000_000_000, 2)}B"
end
