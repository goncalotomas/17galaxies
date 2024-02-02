# Galaxies

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Findings

- Erlang 26 and TLS changes has somewhat broken SMTP connection or made it significantly difficult
- The game needs a server to process events and Oban is sadly not a good fit for processing the game's events
- Processing game events asynchronously without a classic game's closed loop of while(true) update_state is so weird and quirky