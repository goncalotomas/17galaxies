defmodule GalaxiesWeb.PlayerSettingsLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Feel free to change your email address, username or password.</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@username_form}
          id="username_form"
          phx-submit="update_username"
          phx-change="validate_username"
        >
          <.input field={@username_form[:username]} type="text" label="Username" required />
          <.input
            field={@username_form[:current_password]}
            name="current_password"
            id="current_password_for_username"
            type="password"
            label="Current password"
            value={@username_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Username</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/players/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <input
            name={@password_form[:email].name}
            type="hidden"
            id="hidden_players_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_player_email(socket.assigns.current_player, token) do
        :ok ->
          socket
          |> GalaxiesWeb.Common.mount_live_context()
          |> put_flash(:info, "Email changed successfully.")

        :error ->
          socket
          |> GalaxiesWeb.Common.mount_live_context()
          |> put_flash(:error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/players/settings")}
  end

  def mount(_params, _session, socket) do
    player = socket.assigns.current_player
    email_changeset = Accounts.change_player_email(player)
    username_changeset = Accounts.change_player_username(player)
    password_changeset = Accounts.change_player_password(player)

    socket =
      GalaxiesWeb.Common.mount_live_context(socket)
      |> assign(:current_planet, Accounts.get_active_planet(socket.assigns.current_player))
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:username_form_current_password, nil)
      |> assign(:current_email, player.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params

    email_form =
      socket.assigns.current_player
      |> Accounts.change_player_email(player_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("validate_username", params, socket) do
    %{"current_password" => password, "player" => player_params} = params

    username_form =
      socket.assigns.current_player
      |> Accounts.change_player_username(player_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply,
     assign(socket, username_form: username_form, username_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Accounts.apply_player_email(player, password, player_params) do
      {:ok, applied_player} ->
        Accounts.deliver_player_update_email_instructions(
          applied_player,
          player.email,
          &url(~p"/players/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("update_username", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Accounts.update_player_username(player, password, player_params) do
      {:ok, player} ->
        username_form =
          player
          |> Accounts.change_player_username(player_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, username_form: username_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(changeset))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params

    password_form =
      socket.assigns.current_player
      |> Accounts.change_player_password(player_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Accounts.update_player_password(player, password, player_params) do
      {:ok, player} ->
        password_form =
          player
          |> Accounts.change_player_password(player_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
