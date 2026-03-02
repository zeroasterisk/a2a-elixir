# A2A

[![Hex.pm](https://img.shields.io/hexpm/v/a2a.svg)](https://hex.pm/packages/a2a)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/a2a)
[![CI](https://github.com/actioncard/a2a-elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/actioncard/a2a-elixir/actions/workflows/ci.yml)
[![License](https://img.shields.io/hexpm/l/a2a.svg)](LICENSE)
[![AI Assisted](https://img.shields.io/badge/AI-Assisted-blue)](CONTRIBUTIING.md)

Elixir implementation of the [Agent-to-Agent (A2A) protocol](https://google.github.io/A2A/).

A2A enables AI agents to communicate and collaborate through a standardized protocol built on JSON-RPC 2.0.

> **Pre-release**: This library is under active development and not yet published to Hex. The API will change.

> [!NOTE]
> This project is developed with _significant_ AI assistance (Claude, Copilot, etc.)

## Planned Modules

- **`A2A.AgentCard`** — Agent card schema and discovery
- **`A2A.Message`** — Message and artifact types
- **`A2A.Task`** — Task lifecycle and state management
- **`A2A.Router`** — JSON-RPC method routing
- **`A2A.TaskStore`** — Pluggable task persistence
- **`A2A.Plug`** — Plug integration for serving A2A endpoints
- **`A2A.Client`** — HTTP client for calling remote A2A agents

## Installation

Add `a2a` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:a2a, "~> 0.1.0"}
  ]
end
```

### Optional Dependencies

Include only what you need:

```elixir
def deps do
  [
    {:a2a, "~> 0.1.0"},

    # For serving A2A endpoints
    {:plug, "~> 1.16"},
    {:bandit, "~> 1.5"},

    # For calling remote A2A agents
    {:req, "~> 0.5"}
  ]
end
```

## Development

```bash
# Fetch dependencies
mix deps.get

# Run tests
mix test

# Run the full quality suite (format + credo + dialyzer)
mix quality

# Run checks individually
mix format --check-formatted
mix credo --strict
mix dialyzer

# Run the example
mix run examples/demo.exs
```

Requires Elixir ~> 1.17.

### TCK (Protocol Compliance)

The [A2A TCK](https://github.com/a2aproject/a2a-tck) is the official compliance test suite for the A2A protocol. It runs against a live server and validates protocol conformance.

**Prerequisites:** [uv](https://docs.astral.sh/uv/) (Python package manager)

```bash
# Run mandatory compliance tests (clones TCK on first run)
bin/tck mandatory

# Run all categories
bin/tck all

# Available categories: mandatory, capabilities, quality, features, all
```

To run the server manually (e.g. for debugging):

```bash
# Default port 9999
mix run test/tck/server.exs

# Custom port
A2A_TCK_PORT=8080 mix run test/tck/server.exs
```

The TCK runs on every PR in CI. Reports are uploaded as build artifacts.

## Links

- [A2A Protocol Specification](https://google.github.io/A2A/)
- [Hex Package](https://hex.pm/packages/a2a)
- [Documentation](https://hexdocs.pm/a2a)

## License

Apache-2.0 — see [LICENSE](LICENSE).
