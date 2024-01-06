defmodule GalaxiesWeb.PlayerConfirmationInstructionsLiveTest do
  use GalaxiesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Galaxies.AccountsFixtures

  alias Galaxies.Accounts
  alias Galaxies.Repo

  setup do
    %{player: player_fixture()}
  end

  describe "Resend confirmation" do
    test "renders the resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/players/confirm")
      assert html =~ "Resend confirmation instructions"
    end

    test "sends a new confirmation token", %{conn: conn, player: player} do
      {:ok, lv, _html} = live(conn, ~p"/players/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", player: %{email: player.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.get_by!(Accounts.PlayerToken, player_id: player.id).context == "confirm"
    end

    test "does not send confirmation token if player is confirmed", %{conn: conn, player: player} do
      Repo.update!(Accounts.Player.confirm_changeset(player))

      {:ok, lv, _html} = live(conn, ~p"/players/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", player: %{email: player.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      refute Repo.get_by(Accounts.PlayerToken, player_id: player.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/players/confirm")

      {:ok, conn} =
        lv
        |> form("#resend_confirmation_form", player: %{email: "unknown@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "If your email is in our system"

      assert Repo.all(Accounts.PlayerToken) == []
    end
  end
end
