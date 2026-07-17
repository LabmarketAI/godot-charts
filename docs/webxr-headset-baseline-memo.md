# WebXR Headset Baseline Memo

Date: 2026-07-17

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
- Headless runtime check reached:
  - `XR template chart ready: points=4 revision=2`

## Known Gaps

- Right joystick pivot/snap-turn still does not respond in Quest Browser.
- The chart is visible, but its y axis is oriented away from the user.
- The chart currently has no interaction handles or direct manipulation controls.
- The working XR-template experiment is local under `.local/` and intentionally ignored; promote it into tracked source only after the baseline shape settles.

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
- Mount `ChartAnchor` in `game/zones/outside/outside_zone.tscn`.
- Keep single-threaded Web export for Quest Browser compatibility.
