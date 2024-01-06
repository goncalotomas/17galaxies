defmodule Galaxies.Accounts.PlayerNotifier do
  import Swoosh.Email

  alias Galaxies.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Galaxies", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(player, url) do
    deliver(player.email, "Confirmation instructions", """

    ==============================

    Hi #{player.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a player password.
  """
  def deliver_reset_password_instructions(player, url) do
    deliver(player.email, "Reset password instructions", """

    ==============================

    Hi #{player.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a player email.
  """
  def deliver_update_email_instructions(player, url) do
    deliver(player.email, "Update email instructions", """

    ==============================

    Hi #{player.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
