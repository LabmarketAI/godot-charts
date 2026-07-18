# WebXR Headset Baseline Memo

Date: 2026-07-17
Updated: 2026-07-18

## Current Working Baseline

- Device: Meta Quest 3 browser over LAN.
- Stable local host port: `8457`.
- Working local command:
  - `.local/webxr-template/one-shot.sh --port 8457`
- Headset URL observed on Wi-Fi:
  - `https://192.168.0.148:8457/`

## What Works

- The Godot XR template launches in WebXR on the Quest 3.
- The template scene renders with floor, lighting, hands/controllers, and the outdoor zone.
- Left joystick movement works.
- Trigger/button input is reaching the scene.
- A single Godot Charts M1 scatter frame was inserted into the outdoor zone and rendered in headset.
- The chart frame has working lower front handles for whole-frame move and vertical-axis rotate.
- The chart has an experimental first chart-native control pass: X/Y/Z min/max endpoint handles preview and commit retained linear scale-domain changes through `AxisDomainInteractionController`.
- Headless runtime check reached:
  - `XR template chart ready: points=4 revision=2`

## Known Gaps

- Right joystick pivot/snap-turn still does not respond in Quest Browser.
- The chart is visible, but its y axis is oriented away from the user.
- Axis-domain handles are not yet full production analytical controls: they do not have typed parameter resources, undo/reset integration, linked-view propagation, slice planes, thresholds, or selection volumes.
- Endpoint handle placement/selectability needs continued headset validation across Quest Browser runtime updates.

## Local Template Changes To Preserve

- Use the upstream `godotVR/godot-xr-template` as the base scene.
- Keep the template scene structure intact; do not replace it with a scripted mock scene.
- Add the pure-GDScript M1 chart addon via `scripts/build-m1-addon.sh`.
- Copy M1 replay fixtures into the template project.
- Add `game/zones/chart_anchor.gd` to create:
  - `AnalyticalFrame3D`
  - `ScatterRenderer3D`
  - `CartesianGuides3D`
  - M1 replay-backed annual enrollment chart
- Add `game/zones/chart_xr_handles.gd` for whole-chart move/rotate using XR Tools handles.
- Add `game/zones/chart_axis_domain_handles.gd` for experimental X/Y/Z min/max scale-domain controls using semantic visual assets, pointer targets, and XR Tools handle-origin nodes.
- Mount `ChartAnchor` in `game/zones/outside/outside_zone.tscn`.
- Keep single-threaded Web export for Quest Browser compatibility.
