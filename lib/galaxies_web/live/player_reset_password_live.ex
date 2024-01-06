defmodule GalaxiesWeb.PlayerResetPasswordLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Reset Password</.header>

      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.error :if={@form.errors != []}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:password]} type="password" label="New password" required />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label="Confirm new password"
          required
        />
        <:actions>
          <.button phx-disable-with="Resetting..." class="w-full">Reset Password</.button>
        </:actions>
      </.simple_form>

      <p class="text-center text-sm mt-4 text-gray-300">
        <.link class="text-white" href={~p"/players/register"}>Register</.link>
        | <.link class="text-white" href={~p"/players/log_in"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket = assign_player_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{player: player} ->
          Accounts.change_player_password(player)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the player after reset password to avoid a
  # leaked token giving the player access to the account.
  def handle_event("reset_password", %{"player" => player_params}, socket) do
    case Accounts.reset_player_password(socket.assigns.player, player_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/players/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"player" => player_params}, socket) do
    changeset = Accounts.change_player_password(socket.assigns.player, player_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_player_and_token(socket, %{"token" => token}) do
    if player = Accounts.get_player_by_reset_password_token(token) do
      assign(socket, player: player, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "player"))
  end
end
