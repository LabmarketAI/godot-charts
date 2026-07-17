## ADDED Requirements

### Requirement: Device-independent interaction intents
The library SHALL model point, inspect, select, multi-select, brush, filter, navigate, manipulate, and reset as device-independent intents with deterministic state transitions.

#### Scenario: Equivalent selection
- **WHEN** mouse, controller ray, and supported hand input target the same datum with the select intent
- **THEN** they produce the same selection state and event payload

### Requirement: Linked views and provenance
Selection and filter state SHALL be shareable across compatible views and SHALL retain source-row provenance through declared transformations.

#### Scenario: Brush linked plots
- **WHEN** a user brushes a range in one view linked to a second view
- **THEN** both views update from the same selection predicate and expose the selected source rows

### Requirement: Accessible immersive feedback
Interactive targets SHALL provide configurable visual feedback, readable labels, minimum target sizing, and non-color-only selection cues appropriate to the declared viewing distance and input mode.

#### Scenario: XR hover feedback
- **WHEN** an XR ray acquires an inspectable mark
- **THEN** the mark provides visible focus feedback and accessible value text without requiring selection

### Requirement: Embodied coordinate volumes
The library SHALL support spatial views whose data coordinates map deterministically into a documented world-space volume with explicit physical dimensions, origin, orientation, bounds, entry pose, and reset landmark. Users SHALL be able to occupy and move within that volume without changing the underlying data or analytical domains.

#### Scenario: Enter a three-dimensional scatter plot
- **WHEN** a user moves from outside a spatial plot into its declared bounds
- **THEN** axes, guides, labels, marks, selection identity, scale state, and a visible orientation/reset landmark remain coherent from the interior viewpoint

#### Scenario: Walk through data
- **WHEN** user locomotion changes the observer pose within a plot
- **THEN** the data-to-world transform and scale domains remain unchanged and the pose change is reported as navigation rather than analytical zoom

### Requirement: Distinct navigation and analytical transforms
The library SHALL distinguish observer locomotion, view orbit/pan, analytical scale-domain zoom, and whole-plot world transformation as separate reversible operations with independently configurable permissions and bounds.

#### Scenario: Zoom an axis domain
- **WHEN** a user narrows the X domain using scroll, joystick, gesture, or a scale handle
- **THEN** the X scale updates with its new domain visibly indicated while observer pose and plot world transform remain unchanged

#### Scenario: Reset analytical view
- **WHEN** a user invokes reset after navigation, scale, slice, and plot-transform changes
- **THEN** the configured reset scope restores deterministic state and communicates which observer or analytical states were restored

### Requirement: Bindable world-space analytical controls
The library SHALL expose handles, sliders, dials, buttons, and direct-manipulation affordances as renderer presentations of typed analytical parameters. Each binding SHALL declare target path, value type, domain, step or continuous policy, units, constraints, preview/commit behavior, accessible label, and supported input intents.

#### Scenario: Scrub a time parameter
- **WHEN** a user grabs or ray-drags a time slider handle
- **THEN** the bound time parameter previews and commits deterministic revisions while showing its current formatted value and preserving unbound plot state

#### Scenario: Manipulate an axis handle
- **WHEN** a user drags an enabled domain endpoint handle beyond its constraint
- **THEN** the value is clamped or rejected according to the binding and the scale never enters an invalid domain

### Requirement: Spatial slicing and filtering
Spatial plots SHALL support visible, pickable slice planes, range volumes, thresholds, and filter handles that map to normalized predicates or parameters and retain source-row provenance.

#### Scenario: Move a slice plane
- **WHEN** a user translates a Z slice plane through a volume or surface
- **THEN** the visible intersection and inspection results update to the corresponding data-coordinate value and expose the active slice numerically

#### Scenario: Brush a three-dimensional volume
- **WHEN** a user creates or resizes a 3D selection volume
- **THEN** rows inside the declared data-space bounds become selected and linked views receive the same predicate

### Requirement: WebXR interaction parity
The WebXR adapter SHALL provide the supported immersive intent and analytical-control contracts using runtime capability negotiation. Ray plus select SHALL be the baseline input; tracked controllers, squeeze/grab, hand tracking, touch, and other features SHALL enhance but not redefine analytical behavior.

#### Scenario: WebXR controller ray
- **WHEN** a WebXR session provides a pose-capable select input but no hand tracking
- **THEN** the user can inspect, select, operate controls, zoom domains, and reset through ray-based interaction

#### Scenario: WebXR capability loss
- **WHEN** an optional tracked input becomes unavailable during a session
- **THEN** active manipulation terminates safely, uncommitted state follows its declared cancellation policy, and an available fallback input can continue

### Requirement: Comfort and interior readability
Embodied plots SHALL provide configurable locomotion and turning modes, collision/passthrough policy, world scale, label billboarding or anchoring, distance-based detail, occlusion handling, and non-color orientation cues appropriate for exterior and interior viewing.

#### Scenario: Inspect from inside dense data
- **WHEN** interior marks or labels would occlude the selected datum
- **THEN** the configured focus treatment preserves context while making the selected value and its axes coordinates readable
