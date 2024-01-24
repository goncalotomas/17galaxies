defmodule GalaxiesWeb.PlayerConfirmationLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Confirm Account</.header>

      <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
        <.input field={@form[:token]} type="hidden" />
        <:actions>
          <.button phx-disable-with="Confirming..." class="w-full">Confirm my account</.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4 text-gray-300">
        <.link href={~p"/players/register"}>Register</.link>
        | <.link href={~p"/players/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "player")

    {:ok, assign(socket, form: form),
     temporary_assigns: [form: nil], layout: {GalaxiesWeb.Layouts, :single}}
  end

  # Do not log in the player after confirmation to avoid a
  # leaked token giving the player access to the account.
  def handle_event("confirm_account", %{"player" => %{"token" => token}}, socket) do
    case Accounts.confirm_player(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Player confirmed successfully.")
         |> redirect(to: ~p"/overview")}

      :error ->
        # If there is a current player and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the player themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_player: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/overview")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, "Player confirmation link is invalid or it has expired.")
             |> redirect(to: ~p"/")}
        end
    end
  end
end
