# 17 Galaxies

A clone of [OGame](https://lobby.ogame.gameforge.com/) built using Phoenix LiveView.

> [!NOTE]
> This is an work in progress.
>
> 17 Galaxies is an early stage project meant as a demo of what Phoenix and LiveView can do.
> Expect bugs, features missing and other issues.

## Why?

The idea came to me as a way to do project based learning for learning Phoenix LiveView in a way I found to be fun and engaging.

## Trying it out

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Findings

- Erlang 26 and TLS changes has somewhat broken SMTP connection or made it significantly difficult
- The game needs a server to process events and Oban is sadly not a good fit for processing game events
