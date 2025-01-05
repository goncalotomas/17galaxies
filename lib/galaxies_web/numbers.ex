defmodule GalaxiesWeb.Numbers do
  @moduledoc """
  A utility module for displaying different types of numbers in LiveViews
  """

  @doc """
  Formats a countdown timer in seconds into a human-readable string.
  """
  def format_countdown(seconds) when seconds < 0 or seconds == nil, do: ""

  def format_countdown(seconds) do
    minutes = div(seconds, 60)
    hours = div(minutes, 60)
    days = div(hours, 24)
    years = div(days, 365)

    cond do
      years > 0 ->
        "#{years}y #{rem(days, 365)}d #{rem(hours, 24)}h #{rem(minutes, 60)}m #{rem(seconds, 60)}s"

      days > 0 ->
        "#{days}d #{rem(hours, 24)}h #{rem(minutes, 60)}m #{rem(seconds, 60)}s"

      hours > 0 ->
        "#{hours}h #{rem(minutes, 60)}m #{rem(seconds, 60)}s"

      minutes > 0 ->
        "#{minutes}m #{rem(seconds, 60)}s"

      true ->
        "#{seconds}s"
    end
  end

  @doc """
  Formats a number by separating thousands with a dot.
  """
  def format_number(number) when number < 1000, do: to_string(number)

  def format_number(number) do
    number
    |> Kernel.to_string()
    |> String.reverse()
    |> String.split("", trim: true)
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end
end
