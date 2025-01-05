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
end
