# Design: A2A Library Telemetry & Monitoring

## Context

The A2A library already declares `{:telemetry, "~> 1.2"}` as a dependency but emits **zero events**. 

The question: where should instrumentation live, and should the library provide a LiveDashboard page?

## Current State

| Layer | Telemetry? | Notes |
|-------|-----------|-------|
| A2A library | Dep declared, nothing emitted | GenServer-based, clear lifecycle |
| App Collector | Custom Agent-backed observer | Tracks content gen phases, tokens, LLM calls |
| App Telemetry | Full Phoenix/Ecto/Ash/AI metrics | `AppWeb.Telemetry` supervisor |
| LiveDashboard | Standard at `/dev/dashboard` | No custom pages yet |

## Elixir Convention (Ecto/Phoenix/Oban pattern)

The established pattern is a strict separation:

1. **Library emits raw telemetry** — `:telemetry.execute/3` or `:telemetry.span/3` calls in core code. Event names are a public API contract. No UI deps.
2. **Dashboard page is separate** — either in the consuming app, a sibling package, or (like Ecto's page) bundled in `phoenix_live_dashboard` itself. Implements `Phoenix.LiveDashboard.PageBuilder`.
3. **App wires it up** — attaches handlers, registers dashboard pages, decides what to aggregate.

Examples:
- **Ecto**: emits `[:my_app, :repo, :query]` — the LiveDashboard Ecto page lives in `phoenix_live_dashboard`, not Ecto
- **Oban**: emits `[:oban, :job, :start/:stop/:exception]` — Oban Web is a separate package
- **Phoenix**: emits `[:phoenix, :endpoint, :start/:stop]` — consumed by app telemetry config

## Recommendation

### A2A library should emit telemetry events

This is clearly the library's responsibility. Proposed events using `:telemetry.span/3`:

```
[:a2a, :agent, :call]    start/stop/exception — wraps full A2A.call lifecycle
  measurements: %{duration, system_time}
  metadata:     %{agent, task_id, context_id, status}

[:a2a, :agent, :message]  start/stop/exception — wraps handle_message callback
  measurements: %{duration}
  metadata:     %{agent, task_id, message_role}

[:a2a, :agent, :cancel]   start/stop/exception
  measurements: %{duration}
  metadata:     %{agent, task_id}
```

Plus discrete events for state transitions:

```
[:a2a, :task, :transition]
  measurements: %{system_time}
  metadata:     %{agent, task_id, from, to}
```

**Where to emit**: `A2A.Agent.Runtime.process_message/4` (span around `handle_message`), `A2A` module's `call/3` and `stream/3` (span around GenServer.call), and `A2A.Agent.State.transition/2` (discrete event).

### LiveDashboard page: yes, but in the library

Unlike Ecto (whose page is generic enough for `phoenix_live_dashboard` to own), an A2A dashboard page is specific to agent monitoring. It belongs in the A2A library as an optional module — only compiled when `phoenix_live_dashboard` is available:

```elixir
# lib/a2a/dashboard_page.ex
if Code.ensure_loaded?(Phoenix.LiveDashboard.PageBuilder) do
  defmodule A2A.DashboardPage do
    use Phoenix.LiveDashboard.PageBuilder
    # ...
  end
end
```

This is the Oban pattern — library provides the page, app registers it. The page would show:
- Active agents and their task counts
- Recent tasks with status, duration, error rate
- Live task state transitions

### App integration (AppWeb side)

Register the page in the router and optionally attach custom handlers:

```elixir
# router.ex
live_dashboard "/dashboard",
  metrics: AppWeb.Telemetry,
  additional_pages: [a2a: A2A.DashboardPage]
```

Add A2A metrics to `AppWeb.Telemetry.metrics/0`:

```elixir
summary("a2a.agent.call.stop.duration", unit: {:native, :millisecond}, tags: [:agent])
counter("a2a.agent.call.stop.duration", tags: [:agent, :status])
```

## Implementation Order

1. **A2A: Add telemetry spans** to `Runtime.process_message`, `A2A.call/3`, `A2A.stream/3`
2. **A2A: Add transition events** to `State.transition/2`
3. **A2A: Add a `Telemetry` module** documenting all events (like `Oban.Telemetry`)
4. **App: Wire up metrics** in `AppWeb.Telemetry`
5. **A2A: Add optional `DashboardPage`** (can be a follow-up)

## Verification

1. Add a test that attaches a handler and asserts events are emitted on `A2A.call`
2. Verify events appear in LiveDashboard metrics at `/dev/dashboard`
3. `mix compile --warnings-as-errors` in both repos
