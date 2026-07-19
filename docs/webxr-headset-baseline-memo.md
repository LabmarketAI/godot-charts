# WebXR Headset Baseline Memo

Date: 2026-07-17
Updated: 2026-07-19

## Current Working Baseline

- Device: Meta Quest 3 browser over LAN.
- Stable local host port: `8457`.
- Working local command:
  - `.local/webxr-template/one-shot.sh --port 8457`
- Headset URL observed on Wi-Fi:
  - `https://192.168.0.148:8457/`

## What Works

- The Godot XR template launches in WebXR on the Quest 3.
- The template-derived scene renders with floor/safety collision, lighting, hands/controllers, and the shared chart inspection scene.
- Left joystick movement works.
- Trigger/button input is reaching the scene.
- A single Godot Charts M1 scatter frame renders from the editor-authored chart inspection scene in both desktop and WebXR entry points.
- The chart frame has working lower front handles for whole-frame move and vertical-axis rotate where the template frame-handle path is enabled.
- The chart has an experimental first chart-native control pass: X/Y/Z axis scrubbers preview and commit retained linear scale-domain changes through `AxisDomainInteractionController`. The scrubber body pans the visible domain over the fixed extent; min/max edge grips resize the visible span with the opposite edge pinned.
- The VR entry keeps the chart and scrubbers in front of the XR origin and makes controller pointer rays visible for headset debugging.
- Headless runtime check reached:
  - `XR template chart ready: points=4 revision=2`

## Known Gaps

- Right joystick pivot/snap-turn still does not respond in Quest Browser.
- Axis scrubbers are not yet full production analytical controls: they do not have typed parameter resources, undo integration, linked-view propagation, slice planes, thresholds, selection volumes, or final authored GLB scrubber assets.
- Quest/WebXR parity for scrubber select/drag still needs a physical headset pass after each scene-layout change.

## Local Template Changes To Preserve

- Use the upstream `godotVR/godot-xr-template` as the base scene.
- Keep the template scene structure intact; do not replace it with a scripted mock scene.
- Add the pure-GDScript M1 chart addon via `scripts/build-m1-addon.sh`.
- Copy M1 replay fixtures into the template project.
- Use `game/chart_inspection/chart_inspection_root.tscn` as the shared editor-authored chart scene for desktop and VR entry points.
- Keep the chart frame, scatter renderer, guides, lights, labels, floor, and axis scrubber nodes authored in that shared scene.
- Use `game/zones/chart_axis_domain_handles.gd` for X/Y/Z scrubber body and edge controls. Do not recreate scrubbers dynamically at runtime.
- Keep `game/chart_inspection/chart_inspection_desktop.tscn` and `game/chart_inspection/chart_inspection_vr.tscn` as thin entry points around the shared root scene.
- Keep single-threaded Web export for Quest Browser compatibility.
