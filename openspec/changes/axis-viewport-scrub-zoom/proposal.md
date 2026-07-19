## Why

The current chart-axis scrubber prototype mutates scale domains directly, but it does not yet model the interaction as a viewport window over a stable data extent. On desktop this makes an X scrub feel like it shoves marks to one side instead of behaving like timeline and editor scrollbars: the scrubber body should pan a visible domain window, end drags should resize that window, and zoom controls should expand or contract the visible range around a declared focus.

Ardour and Blender both solve this by separating overview extents from visible range. Ardour's Summary and MIDI scroomer use a draggable body for panning the visible range and draggable borders/handles for changing zoom. Blender timeline and graph editor navigation likewise distinguish panning, zooming, axis-specific scaling, scrollbars, and fit/reset commands.

We need to capture those conventions before changing more runtime code so desktop and WebXR implement the same chart interaction contract.

## What Changes

- Define a first-class axis viewport model with immutable data extent, mutable visible domain, normalized scrubber window, minimum span, clamping, and reset/fit behavior.
- Replace "free handle moves a domain edge" semantics for 2D axis controls with axis-attached scrubber semantics.
- Specify desktop and WebXR input parity:
  - drag scrubber body to pan the visible domain window;
  - drag one end to resize/zoom with the opposite end pinned;
  - drag both ends or pinch/scale to zoom around center/focus where supported;
  - scroll/joystick/keyboard zoom around a declared focus;
  - double-click/reset fits full data extent.
- Require the scrubber visual window to update continuously and communicate how zoomed in the user is.
- Require plotted marks to be clipped/remapped through the scale viewport rather than translated as standalone objects.
- Add deterministic tests for pan, edge resize, center zoom, clamping, reset, and desktop/WebXR event equivalence.

## Impact

- Primary impact: axis-domain interaction controller, scale/domain state, chart scrubber scene nodes, desktop mouse picking, WebXR pointer/select handling, and chart renderers that consume visible domains.
- Supporting impact: OpenSpec interaction docs, M2/M3 tests, WebXR template chart inspection scene, visual asset role catalog for axis scrubber rails/windows/thumbs, and release evidence.
- This change does not replace data filtering, brushing, camera navigation, or whole-chart transforms. It defines analytical viewport navigation for chart axes.
