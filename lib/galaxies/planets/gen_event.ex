defmodule Galaxies.Planets.GenEvent do
  @moduledoc """
  Defines the behaviour for a generic game event.
  """
  alias Galaxies.Planet
  alias Galaxies.Planets.PlanetEvent

  @doc """
  The main callback for a generic event, taking in the planet where the event takes place
  as well as a PlanetEvent struct. The event struct may not have all the required information
  to process the event and subsequent queries may be needed to sub-queues (e.g. building_queue).
  It's possible that processing an event generates more events, so the callback expects a tuple
  `{:ok, events}` as the success return for this function.
  Events are processed in sequence for each `planet_id` in order of the `completed_at` timestamp.
  For the event list `[e1, e2, e3]`, if processing `e1` would generate two events, `[e4, e5]`, both
  of them completing before e2 and e3, the Event Processor Module will re-sort the list of events
  (e.g. `[e4, e5, e2, e3]`) before processing any other event in the queue. Additionally, the event
  processor processes events up to a specific timestamp and discards any returned events outside of
  that time interval.
  """
  @callback process(planet :: Planet, event :: PlanetEvent) ::
              {:ok, list(PlanetEvent)}
end
