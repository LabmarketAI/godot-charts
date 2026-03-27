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

Additional runtime check:

- OS/runtime: Windows Godot console executable (`Godot_v4.7-dev3_mono_win64_console.exe`) invoked from WSL

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

4. Attempt headless demo run with Windows Godot console:

```bash
"C:/Users/b/Desktop/Godot_v4.7-dev3_mono_win64/Godot_v4.7-dev3_mono_win64/Godot_v4.7-dev3_mono_win64_console.exe" --path demo --headless --scene res://scenes/main.tscn --quit-after 45
```

Result: PARTIAL / BLOCKED

- Process exits cleanly (`EXIT:0`)
- Desktop capture backend initializes and captures frames
- Runtime still logs `CircuitChart3D` `IndexOutOfRangeException` during scene processing

## Runtime Failure Evidence

Observed startup blockers in headless Linux environment:

- `godot-desktop-capture` native extension fails to load on Linux:
  - `undefined symbol: pw_stream_queue_buffer`
- OpenXR runtime enumeration failures (falls back to normal mode)
- During scene startup, `Main.SetupWorkspaceAndConsole()` reports:
  - `Node not found: "DataRoom" (relative to "/root/Main")`
  - Followed by `NullReferenceException` in `FrameOrchestrationService.Initialize(...)`

Because scene initialization fails early in this environment, visual chart update verification cannot complete here.

Windows-console run notes:

- Startup succeeds further than Linux headless path
- `DesktopCapture` starts and reports active window capture
- However, `CircuitChart3D` runtime exception remains a blocker for declaring full clean smoke pass
- `demo_stream` validation for all chart families also requires runtime frames configured to `demo_stream`; default startup content is static scene content and does not automatically prove one update cycle per chart family

## Checklist

| Check | Status | Notes |
|---|---|---|
| Bar receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |
| Line receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |
| Scatter receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |
| Histogram receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |
| Surface receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |
| Graph network receives at least one stream payload update | Blocked | Requires runtime frame in `demo_stream`; not auto-provisioned in headless startup |

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
- Linux headless smoke: BLOCKED by native extension/runtime startup issues
- Windows-console headless smoke: PARTIAL (startup and capture run, but blocked by `CircuitChart3D` runtime exception and lack of preconfigured `demo_stream` runtime frames)
- Runtime bus-to-chart data path is now wired in code and ready for desktop visual confirmation
