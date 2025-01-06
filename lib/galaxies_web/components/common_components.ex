defmodule GalaxiesWeb.CommonComponents do
  alias GalaxiesWeb.Numbers
  use Phoenix.Component

  use Gettext, backend: GalaxiesWeb.Gettext

  attr :events, :list, required: true

  def build_queue(assigns) do
    # TODO look into replacing with <.table>
    ~H"""
    <div>
      <h4 class="text-base font-medium leading-4 text-gray-800">
        Active Build Queue
      </h4>
    </div>
    <div class="mt-2 flow-root">
      <div class="mx-4 my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th
                  scope="col"
                  class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6 lg:pl-8"
                >
                  Building
                </th>
                <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                  Level
                </th>
                <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                  Time to Complete
                </th>
                <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6 lg:pr-8">
                  <span class="sr-only">Cancel</span>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr>
                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6 lg:pl-8">
                  {hd(@events).building.name}
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  {hd(@events).level}
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  <span
                    id="build-queue-countdown"
                    phx-hook="Countdown"
                    data-target={DateTime.add(hd(@events).completed_at, 2, :second)}
                  >
                    {Numbers.format_countdown(
                      DateTime.diff(hd(@events).completed_at, DateTime.utc_now())
                    )}
                  </span>
                </td>
                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6 lg:pr-8">
                  <a
                    href="#"
                    phx-click={"cancel:#{hd(@events).id}"}
                    class="text-indigo-600 hover:text-indigo-900"
                  >
                    Cancel<span class="sr-only">, {hd(@events).building.name}</span>
                  </a>
                </td>
              </tr>
              <tr :for={queued <- tl(@events)}>
                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6 lg:pl-8">
                  {queued.building.name}
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  {queued.level}
                </td>
                <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                  -
                </td>
                <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6 lg:pr-8">
                  <a href="#" class="text-indigo-600 hover:text-indigo-900">
                    Cancel<span class="sr-only">, {queued.building.name}</span>
                  </a>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  attr :formula, :string, required: true
  attr :level, :integer, required: true

  def upgrade_cost(assigns) do
    {metal, crystal, deuterium, energy} =
      Galaxies.calc_upgrade_cost(assigns.formula, assigns.level)

    assigns = %{metal: metal, crystal: crystal, deuterium: deuterium, energy: energy}

    ~H"""
    Requirements:
    <%= if @metal > 0 do %>
      Metal: <strong>{Numbers.format_number(@metal)}</strong>
    <% end %>
    <%= if @crystal > 0 do %>
      Crystal: <strong>{Numbers.format_number(@crystal)}</strong>
    <% end %>
    <%= if @deuterium > 0 do %>
      Deuterium: <strong>{Numbers.format_number(@deuterium)}</strong>
    <% end %>
    <%= if @energy > 0 do %>
      Energy: <strong>{Numbers.format_number(@energy)}</strong>
    <% end %>
    """
  end
end
