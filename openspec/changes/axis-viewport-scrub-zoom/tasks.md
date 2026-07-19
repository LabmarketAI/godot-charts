## 1. Interaction Model

- [x] 1.1 Introduce explicit axis viewport state with full extent, visible domain, min span, optional max span, focus policy, and overscroll policy.
- [x] 1.2 Decide whether viewport state lives in `LinearScale`, `AnalyticalFrameState`, or a dedicated `AxisViewport` object, and document the choice.
- [x] 1.3 Preserve backward compatibility for existing linear scales that only declare `domain_min` and `domain_max`.
- [x] 1.4 Add deterministic domain math for body pan, min-edge resize, max-edge resize, centered zoom, clamping, cancel, commit, and reset.

## 2. Renderer Behavior

- [x] 2.1 Ensure marks are remapped through the visible domain into a fixed plot volume rather than translated as independent objects.
- [x] 2.2 Define and implement clipping/fade policy for marks outside the visible domain.
- [x] 2.3 Update guides, ticks, labels, and diagnostics from visible domain while preserving full extent metadata.
- [x] 2.4 Expose current viewport state in diagnostics and session snapshots.

## 3. Scrubber Presentation

- [x] 3.1 Replace prototype fixed-size scrubber windows with windows whose position and size reflect `visible_domain / extent`.
- [x] 3.2 Keep scrubber body, min edge, max edge, focus marker, labels, and reset target editor-authored and visible in the shared scene.
- [ ] 3.3 Add visual states for idle, hover, active drag, clamped edge, invalid preview, and reset-ready.
- [x] 3.4 Add or update semantic asset roles for axis scrubber rail, visible window, edge grip, focus marker, and reset target.

## 4. Desktop Input

- [x] 4.1 Left-drag scrubber body pans the visible domain and moves the scrubber body accordingly.
- [x] 4.2 Left-drag min/max edge resizes the visible domain with the opposite edge pinned.
- [x] 4.3 Mouse wheel over plot/axis zooms around the pointer or configured focus.
- [x] 4.4 Escape cancels active previews; double-click or reset target fits full extent.
- [ ] 4.5 Add a desktop smoke path that exercises body pan, edge resize, wheel zoom, reset, and cancellation.

## 5. WebXR Input

- [x] 5.1 Ray/select scrubber body pans the visible domain.
- [x] 5.2 Ray/select scrubber edge resizes the visible domain.
- [ ] 5.3 Controller thumbstick or equivalent input can nudge pan/zoom without changing semantics.
- [ ] 5.4 Optional two-controller pinch scales the visible span around midpoint focus when available.
- [ ] 5.5 Verify Quest/WebXR parity against the desktop smoke path and record host logs.

## 6. Tests and Acceptance

- [x] 6.1 Add unit tests for pan preserving span, min/max edge pinning, centered zoom, clamping, reset, and cancellation.
- [ ] 6.2 Add scene tests that scrubber window geometry matches normalized visible domain.
- [x] 6.3 Add renderer tests that out-of-domain marks are clipped or faded according to policy.
- [x] 6.4 Add regression test for the observed desktop failure: X body scrub must move the visible viewport over fixed data extent, not move chart objects or leave scrubber geometry stale.
- [x] 6.5 Update docs and demo labels so users understand body pan, edge zoom, wheel zoom, and reset behavior.
