## Research Summary

### Ardour Summary and Scroomer

Ardour uses overview controls to communicate and manipulate the visible portion of a larger session or pitch range. The Summary shows a global overview with a visible-view rectangle; dragging the rectangle moves the editor view, while resizing its left/right borders zooms in or out. The MIDI scroomer applies the same model vertically: dragging the middle shifts the visible note range, dragging the top or bottom handle expands or shrinks the visible range, and double-clicking fits the visible range to content.

Relevant sources:
- Ardour Navigating the Editor: https://manual.ardour.org/editing/navigating-the-editor/
- Ardour Controlling Visible Note Range: https://manual.ardour.org/working-with-midi/controlling-midi-range/
- Ardour Zoom Controls: https://manual.ardour.org/ardours-interface/the-zoom-controls/

Key interaction principles:
- The overview extent and visible range are different things.
- Dragging the scrubber body pans the visible range without changing its span.
- Dragging a boundary changes the visible span with the opposite boundary effectively pinned.
- Zoom has a focus policy: left, right, center, playhead/edit point, mouse, or selection.
- Fit/reset restores the visible range to content/session extents.
- Continuous redraw during drag is important because the user is steering by feedback.

### Blender Timeline and Graph Editor

Blender exposes pan, zoom, fit, current-frame focus, scrollbars, and axis-specific scaling. Timeline navigation supports panning, zooming, scrollbars, fit-to-scene/preview range, and playhead scrubbing. The graph editor adds axis-specific scaling: zoom uniformly with wheel or plus/minus, scale the view horizontally or vertically with modified drag, or drag scrollbar ends.

Relevant sources:
- Blender Timeline manual: https://docs.blender.org/manual/fi/5.0/editors/timeline.html
- Blender Graph Editor navigation summary: https://wiki.blender.jp/%E5%88%A9%E7%94%A8%E8%80%85%3ATnboma/Doc%3A2.5/Manual/Animation/Graph_Editor

Key interaction principles:
- Panning the view is distinct from moving content.
- Zooming changes the mapping between data/time/value and screen, not object ownership.
- Axis-specific zoom is a normal interaction, especially in curve/graph editors.
- Fit all, frame range, and current-frame focus are explicit commands.
- The control itself provides feedback about current visible span relative to the full extent.

## Product Interpretation for Godot Charts

### Data Model

Axis scrubbers should not own chart marks. They should edit an axis viewport:

- `extent_min`, `extent_max`: full data or declared useful extent.
- `visible_min`, `visible_max`: current scale domain shown in the plot.
- `min_span`: smallest allowed visible span.
- `max_span`: usually `extent_max - extent_min`, unless the plot permits overscroll.
- `focus`: normalized anchor used for wheel/joystick/button zoom.
- `allow_overscroll`: default false for analytical charts.

The renderer maps data values through `visible_min..visible_max` into a fixed plot volume. Marks outside the visible domain are clipped or faded according to renderer policy. Marks are not translated by the scrubber.

Implementation decision for the initial slice: viewport state lives on `LinearScale`. Existing `domain_min` and `domain_max` remain the visible domain for backward compatibility. New `extent_min`, `extent_max`, `min_span`, `max_span`, `focus`, and `allow_overscroll` fields describe the scrubber rail and viewport constraints. A later dedicated `AxisViewport` object can wrap this state if non-linear, temporal, or categorical axis viewport rules require more structure.

### Scrubber Geometry

Each axis scrubber should be an authored axis-attached assembly:

- `control/axis_scrubber_rail`: full extent.
- `control/axis_scrubber_window`: visible domain window/body, positioned and sized as a normalized interval over the rail.
- `control/axis_scrubber_edge`: min and max edge grips/handles for resizing the visible window.
- `control/axis_scrubber_focus`: optional marker showing zoom focus when wheel/joystick zoom is active.
- reset/fit affordance: optional button or double-select target.

The body length communicates how zoomed in the user is. A short body means a narrow visible domain; a full-length body means fit-to-extent.

### Interaction Semantics

Body drag:
- Preserves visible span.
- Moves both visible edges by the same domain delta.
- Clamps at extent bounds unless overscroll is enabled.
- Updates the scrubber window position and the plotted marks continuously.

Min edge drag:
- Pins `visible_max`.
- Changes `visible_min`.
- Clamps to `extent_min` and `visible_max - min_span`.
- Updates body size and position continuously.

Max edge drag:
- Pins `visible_min`.
- Changes `visible_max`.
- Clamps to `visible_min + min_span` and `extent_max`.
- Updates body size and position continuously.

Centered zoom:
- Changes visible span around a focus point.
- Focus can be center, pointer hit, current selected datum, or explicit axis marker.
- Clamps to `min_span` and full extent.

Two-handed or pinch zoom:
- Treats the distance between two active inputs as a span controller.
- Treats midpoint as focus unless a stronger focus policy is active.
- Falls back to one-handed edge/body drag when only one input is available.

Reset/fit:
- Restores visible domain to the current extent.
- Leaves camera pose and chart world transform unchanged.

### Desktop Input Contract

- Left-drag body: pan visible domain.
- Left-drag min/max edge: resize visible domain with the opposite edge pinned.
- Mouse wheel over plot or axis: zoom around mouse position or configured focus.
- Shift or equivalent modifier over axis: axis-only zoom if global wheel zoom would otherwise apply both axes.
- Double-click scrubber body or reset target: fit full extent.
- Escape: cancel active preview and restore pre-drag visible domain.

### WebXR Input Contract

- Ray/select body: pan visible domain along the axis.
- Ray/select edge: resize visible domain with opposite edge pinned.
- Controller thumbstick over active axis: nudge pan or zoom according to active mode.
- Two controller rays, if available: pinch/scale visible span with midpoint focus.
- Reset affordance must be reachable by ray/select and not require browser tab closure.

### Current Prototype Failure Mode

The desktop prototype has the right high-level control shape but not the full viewport contract. It updates a scale domain from drag delta, but the scrubber window is not yet the authoritative visual representation of a visible interval over a stable extent. This lets the data movement read as "marks shoved to one side" rather than "the viewport sliding over data." The fix is not another local drag multiplier; the fix is to introduce explicit axis viewport state and make both the scrubber visual and renderer read from that state.

## Open Decisions

- Whether axis viewport state belongs inside `LinearScale`, a wrapper `AxisViewport`, or `AnalyticalFrameState`.
- Whether extents are inferred from data on every figure update, declared by the figure, or both with an explicit override.
- Whether out-of-domain marks are clipped hard, faded near edges, or hidden per renderer.
- Whether 3D plots use the same scrubber vocabulary on all axes or reserve this model for 2D and 2.5D charts.
- Whether WebXR two-handed pinch is required for M3 or deferred behind ray/select edge dragging.
