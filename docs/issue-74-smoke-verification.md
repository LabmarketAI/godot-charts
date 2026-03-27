# Issue #74 Smoke Verification Report

Parent issue: #55
Tracker: #69

Date: 2026-03-27
Branch context: issue-73-console-bus-controls -> issue-74-smoke-verification (stacked)

## Scope

Smoke-verify that demo stream payloads can drive chart updates for all supported chart families in the #72 payload generator contract:

- bar
- line
- scatter
- histogram
- surface
- graph_network

## Environment

- OS used for automated checks: Linux (WSL)
- Godot runtime attempted: 4.7-dev3 mono (headless)
- Demo path: `demo/`

## Commands Executed

1. Build demo project:

```bash
dotnet build demo/GodotChartsDemo.csproj -v minimal
```

Result: PASS

2. Run existing test suite:

```bash
dotnet test tests/GodotChartsTests.csproj -v minimal
```

Result: PASS (41/41)

3. Attempt headless demo run:

```bash
~/.gdvm/bin/godot --headless --path demo --scene res://scenes/main.tscn --quit-after 35
```

Result: BLOCKED (runtime initialization failure before stable frame render loop)

## Runtime Failure Evidence

Observed startup blockers in headless Linux environment:

- `godot-desktop-capture` native extension fails to load on Linux:
  - `undefined symbol: pw_stream_queue_buffer`
- OpenXR runtime enumeration failures (falls back to normal mode)
- During scene startup, `Main.SetupWorkspaceAndConsole()` reports:
  - `Node not found: "DataRoom" (relative to "/root/Main")`
  - Followed by `NullReferenceException` in `FrameOrchestrationService.Initialize(...)`

Because scene initialization fails early in this environment, visual chart update verification cannot complete here.

## Checklist

| Check | Status | Notes |
|---|---|---|
| Bar receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |
| Line receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |
| Scatter receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |
| Histogram receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |
| Surface receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |
| Graph network receives at least one stream payload update | Blocked | Runtime startup failure prevents frame verification in current environment |

## Code-level Verification Added

To align stream behavior with #74 intent, `DataBindingService` now consumes `MessageBusService.MessageReceived` and routes canonical payloads by chart topic:

- topic routing normalized to `demo/stream/{chart_type}`
- frame subscriptions normalized by chart type for `demo_stream`
- payload adapters added for:
  - point-series datasets (`line`, `scatter`) to `Vector3` points
  - graph edge key normalization (`from/to` -> `source/target`)
  - histogram envelope to raw sample reconstruction
- local synthetic `_Process` stream updates are bypassed while message bus is running

This enables bus-delivered runtime updates once the scene starts successfully in a compatible environment.

## Reproduction Steps for Local Visual Smoke (Windows desktop)

1. Open `demo/project.godot` in Godot 4.7 mono.
2. Run `res://scenes/main.tscn` (non-headless desktop run).
3. Press `F1` to open diegetic console.
4. Ensure runtime frames are set to `demo_stream` binding.
5. Verify `Data stream bus` status is `running`.
6. Wait >= 30 seconds and confirm each chart family updates at least once.
7. If needed, use `Start Stream` / `Stop Stream` controls to test pause/resume behavior.

## Conclusion

- Automated build/test checks: PASS
- Full visual smoke verification in this Linux headless environment: BLOCKED by native extension/runtime startup issues
- Runtime bus-to-chart data path is now wired in code and ready for desktop visual confirmation
