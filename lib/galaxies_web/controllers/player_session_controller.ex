defmodule GalaxiesWeb.PlayerSessionController do
  use GalaxiesWeb, :controller

  alias Galaxies.Accounts
  alias GalaxiesWeb.PlayerAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:player_return_to, ~p"/players/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"player" => player_params}, info) do
    %{"email" => email, "password" => password} = player_params

    if player = Accounts.get_player_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> PlayerAuth.log_in_player(player, player_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/players/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> PlayerAuth.log_out_player()
  end
end
