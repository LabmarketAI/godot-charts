## ADDED Requirements

### Requirement: Axis Viewport Scrub And Zoom
The library SHALL model axis scrubbers as viewport controls over stable analytical extents. Each controlled quantitative axis SHALL distinguish the full data or declared useful extent from the currently visible domain, and SHALL expose deterministic preview, commit, cancel, clamp, and reset behavior.

#### Scenario: Scrub visible domain without changing zoom
- **WHEN** a user drags the body of an axis scrubber along its rail
- **THEN** the visible domain pans by the corresponding data-space delta while preserving its span
- **AND** the visible domain is clamped to the declared extent unless overscroll is enabled
- **AND** the chart frame transform, observer pose, and full data extent remain unchanged

#### Scenario: Resize visible domain from minimum edge
- **WHEN** a user drags the minimum edge of an axis scrubber
- **THEN** the visible minimum changes while the visible maximum remains pinned
- **AND** the visible span is clamped to the configured minimum span and full extent
- **AND** invalid previews are rejected or clamped without producing an invalid scale domain

#### Scenario: Resize visible domain from maximum edge
- **WHEN** a user drags the maximum edge of an axis scrubber
- **THEN** the visible maximum changes while the visible minimum remains pinned
- **AND** the visible span is clamped to the configured minimum span and full extent
- **AND** invalid previews are rejected or clamped without producing an invalid scale domain

#### Scenario: Zoom around focus
- **WHEN** a user invokes axis zoom through wheel, joystick, button, gesture, or supported pinch input
- **THEN** the visible domain expands or contracts around the active focus policy
- **AND** the focus policy is reported as center, pointer, selection, marker, or configured default
- **AND** the operation does not change unbound axes unless the interaction explicitly requests multi-axis zoom

#### Scenario: Reset axis viewport
- **WHEN** a user invokes fit or reset on an axis scrubber
- **THEN** the visible domain returns to the declared full extent for that axis
- **AND** the operation does not reset observer pose, whole-plot transform, selection, or unrelated axis domains unless the reset scope declares those targets

### Requirement: Scrubber Window Presentation
Axis scrubber visuals SHALL continuously represent the visible domain as a normalized window over the full extent. The scrubber body size SHALL communicate zoom level, and the body position SHALL communicate which portion of the extent is visible.

#### Scenario: Body position tracks visible domain
- **WHEN** the visible domain is `[visible_min, visible_max]` inside extent `[extent_min, extent_max]`
- **THEN** the scrubber body starts at `(visible_min - extent_min) / (extent_max - extent_min)`
- **AND** ends at `(visible_max - extent_min) / (extent_max - extent_min)`
- **AND** updates during preview, commit, cancel, reset, and external domain changes

#### Scenario: Full extent is visible
- **WHEN** the visible domain equals the full extent
- **THEN** the scrubber body fills the rail
- **AND** edge grips remain discoverable without implying further zoom-out is available

#### Scenario: Clamped preview feedback
- **WHEN** a user drags beyond the configured extent or minimum span
- **THEN** the scrubber provides non-color-only clamped feedback
- **AND** the committed viewport remains valid

### Requirement: Fixed Plot Volume During Axis Viewport Changes
Axis viewport changes SHALL update scale mapping and renderer visibility inside the fixed chart plot volume. Marks, guides, and labels SHALL be recomputed from the visible domain; the chart frame and data objects SHALL NOT be translated as a substitute for viewport panning.

#### Scenario: Pan X viewport in a fixed chart
- **WHEN** a user pans the X visible domain by dragging the X scrubber body
- **THEN** marks are remapped through the new X visible domain into the same plot volume
- **AND** marks outside the visible domain are clipped or faded according to renderer policy
- **AND** the chart frame, axes, floor, observer camera, and unrelated Y/Z visible domains remain unchanged

#### Scenario: Edge zoom updates guides
- **WHEN** a user resizes an axis viewport from one scrubber edge
- **THEN** ticks, labels, grid guides, and diagnostics update to the new visible domain
- **AND** the scrubber window changes size and position to match the new normalized interval

### Requirement: Desktop And WebXR Axis Viewport Parity
Desktop mouse/keyboard, WebXR ray/select, controller input, and supported gesture input SHALL route to the same axis viewport operations and produce equivalent state transitions for the same target axis and delta.

#### Scenario: Desktop body drag equals WebXR ray body drag
- **WHEN** desktop mouse drag and WebXR ray/select drag apply the same normalized body delta to the same axis viewport
- **THEN** both produce the same previewed and committed visible domain
- **AND** both emit equivalent diagnostics and interaction events

#### Scenario: Cancel restores pre-drag viewport
- **WHEN** a desktop Escape, WebXR capability loss, or explicit cancel occurs during an axis viewport preview
- **THEN** the visible domain, scrubber window, guides, and rendered marks restore to their pre-drag state
