## ADDED Requirements

### Requirement: Persistent frame identity and lifecycle
A chart frame SHALL be a stable session object with identifier, transform, bounds, presentation/theme reference, visibility, lock and permission state, content binding, local view state, status, and provenance. The library SHALL support create, preview-place, commit, duplicate, snapshot, rebind, hide/show, lock/unlock, reset, and delete lifecycle commands without requiring a demo application service.

#### Scenario: Place a new frame
- **WHEN** a user selects a source or plot and begins frame creation
- **THEN** the library presents a bounded placement preview with size, orientation, collision/docking feedback, content summary, and explicit commit/cancel behavior before creating persistent state

#### Scenario: Duplicate a live frame
- **WHEN** a user duplicates a frame bound to a live plot
- **THEN** the new frame receives a distinct frame identity and declared shared-or-independent view state while retaining an explicit binding to the same plot source

#### Scenario: Delete with undo
- **WHEN** a user deletes a frame and then invokes undo within retained history
- **THEN** its identity, transform, binding, theme, local view state, and relationships are restored unless an external permission or unavailable source requires a diagnosed fallback

### Requirement: Separate frame, plot, and binding state
The system SHALL keep frame presentation state, normalized plot/analytical state, source data or plot revisions, and transport subscription state independently addressable. Changing frame transform, dimensions, chrome, theme, or visibility SHALL NOT mutate source data or the remote published plot.

#### Scenario: Move a streaming chart
- **WHEN** a frame receiving live updates is moved or rotated
- **THEN** its source subscription and plot revision continue unchanged while only frame transform state changes

#### Scenario: Rebind a frame
- **WHEN** a frame is rebound to another compatible source
- **THEN** the previous binding remains recoverable through undo/history and local view state is retained, migrated, or reset according to an explicit compatibility result

### Requirement: Explicit content, frame, and layout modes
Input routing SHALL distinguish content interaction, single-frame manipulation, and multi-frame layout operations. The active mode, captured target, permitted operations, constraints, and cancel path SHALL be visible and accessible. Ambiguous scroll, pinch, grab, ray, or two-hand input SHALL NOT modify both plot and frame state in one gesture.

#### Scenario: Scroll over chart content
- **WHEN** content mode owns focus and the user scrolls over an axis-enabled plot
- **THEN** the declared analytical zoom or scroll action occurs and frame dimensions remain unchanged

#### Scenario: Resize a frame
- **WHEN** frame mode captures a resize handle
- **THEN** movement previews constrained frame bounds and applicable content reflow while analytical domains remain unchanged unless an explicitly linked responsive policy applies

#### Scenario: Cancel direct manipulation
- **WHEN** tracking is lost or the user cancels during move, rotate, resize, or docking
- **THEN** uncommitted frame state follows the declared rollback policy and content focus can be restored safely

### Requirement: Frame selection and manipulation
The library SHALL support hover/focus, single selection, additive/toggle multi-selection, select-all-in-scope, clear selection, and locked or permission-limited selection. Selected frames SHALL expose accessible move, rotate, resize, aspect, depth, dock, snap, grab, and reset affordances appropriate to the input mode and performance tier.

#### Scenario: Multi-select frames
- **WHEN** a user additively selects several frames
- **THEN** every selected identity and primary selection are visible and compatible layout commands report their effect before commit

#### Scenario: Manipulate a locked frame
- **WHEN** a user attempts a prohibited transform on a locked or read-only frame
- **THEN** no persistent transform changes and the frame communicates the lock/permission and available alternatives

### Requirement: Stream and plot discovery
The library SHALL expose a transport-neutral catalog of available static plots, published plot specifications, raw/typed streams, derived views, and snapshots. Catalog entries SHALL provide stable source identity, title, description, topic or locator, semantic schema/fields, units, suggested representations, update cadence, freshness, preview, permission, and connection status where supplied.

#### Scenario: Browse longitudinal streams
- **WHEN** a user searches for “number of trials per year”
- **THEN** matching sources show their semantic fields, units, freshness, publisher representation, compatible local representations, and preview before subscription

#### Scenario: Source is unavailable
- **WHEN** a catalog source disconnects or expires
- **THEN** bound frames display an explicit stale/offline state, last-good revision and timestamp, and configured reconnect or fallback behavior without presenting stale data as live

### Requirement: Representation policy and chart-style choice
Every binding SHALL declare one of `follow_source`, `suggest_source`, `user_locked`, or `derived` representation policies. A published plot specification SHALL be reproduced under `follow_source`; semantic data streams MAY advertise and preview compatible local representations. Local representation changes SHALL preserve provenance, SHALL validate required fields/scales, and SHALL NOT mutate the publisher.

#### Scenario: Follow a published line plot
- **WHEN** the “number of trials per year” source publishes a line-plot specification and the frame follows the source
- **THEN** the frame renders that longitudinal line representation and accepts compatible source revisions without silently switching chart type

#### Scenario: Re-express compatible raw data
- **WHEN** the same source exposes typed year and trial-count fields and the user chooses a compatible bar representation
- **THEN** the frame previews and applies a local representation override, records its provenance and policy, and retains a reset-to-source action

#### Scenario: Choose an incompatible style
- **WHEN** a requested surface representation lacks the required spatial/grid fields
- **THEN** the library disables or rejects it with missing requirements and suggests compatible representations rather than fabricating dimensions

### Requirement: Binding revision and schema-change handling
Frames bound to live sources SHALL process idempotent ordered revisions, expose receiving/live/paused/stale/error states, and apply declared buffering, pause, snapshot, resume, and reconnect policies. A schema or plot-kind change SHALL be compatibility-checked before replacing active content.

#### Scenario: Publisher changes representation
- **WHEN** a following source replaces a compatible line plot with a materially different plot specification
- **THEN** the frame previews or applies the change according to its policy, preserves the last-good revision, and reports any lost local view state

#### Scenario: Pause a stream frame
- **WHEN** a user pauses a live frame
- **THEN** the visible revision and timestamp remain fixed while the declared buffer/drop policy and resume consequence are visible

### Requirement: Multi-frame layout and relationships
The library SHALL support align, distribute, tile, stack, dock, snap, group/ungroup, isolate, compare, and focus/teleport operations over selected frames. Frames MAY link compatible selection, filter, domain, camera, cursor, time, parameter, or playback state through explicit directional or bidirectional relationships.

#### Scenario: Create a comparison pair
- **WHEN** a user selects two compatible frames and invokes compare
- **THEN** the session establishes a declared spatial layout and optional linked domains/selections without merging their source identities

#### Scenario: Link incompatible domains
- **WHEN** a user attempts to link axes with incompatible types or units and no conversion is declared
- **THEN** the relationship is rejected or limited with an actionable compatibility diagnostic

### Requirement: Session history, persistence, and recovery
The library SHALL maintain bounded command history for frame and relationship mutations and SHALL serialize versioned session state including frames, transforms, bindings, policies, local overrides, themes, groups, links, visibility, locks, and last-good source metadata. Save/restore SHALL be crash-safe and SHALL diagnose missing sources, assets, themes, permissions, and schema migrations.

#### Scenario: Restore a session
- **WHEN** a saved session is reopened
- **THEN** frames and relationships restore deterministically, live bindings reconnect according to policy, and unresolved dependencies use explicit placeholders or fallbacks

#### Scenario: Undo while data continues
- **WHEN** a user undoes a frame move while its source publishes new plot revisions
- **THEN** only the frame transform command is reversed and incoming plot state remains governed by the binding policy

### Requirement: Frame status, provenance, and chrome
Frame chrome SHALL provide configurable, themeable presentations for title, source identity, freshness/revision, connection state, representation policy, local-modification state, selection/lock/permission, and available frame actions. Chrome SHALL be collapsible and SHALL remain discoverable through accessible focus or inspection when visually minimized.

#### Scenario: Inspect local override
- **WHEN** a frame displays a user-locked representation different from its publisher suggestion
- **THEN** its status identifies the local override and exposes compare-to-source and reset-to-source actions

### Requirement: Input and accessibility parity
Core frame lifecycle, selection, binding, status, manipulation, layout, undo, and reset operations SHALL be available through supported desktop and immersive input paths. WebXR ray/select SHALL provide the baseline; direct grab, tracked hands, controllers, touch, mouse, and keyboard SHALL map to the same commands and state transitions.

#### Scenario: Operate frames with WebXR ray
- **WHEN** a WebXR user has ray/select input without hand tracking
- **THEN** they can select, create, place, move, resize, bind, restyle, lock, hide, restore, and delete frames and can cancel or undo each mutating workflow

### Requirement: Frame scalability and visibility policy
The library SHALL define budgets and adaptive policies for frame count, active subscriptions, visible marks, labels, interaction targets, update cadence, and persistence size. Off-screen, occluded, minimized, distant, or hidden frames MAY reduce rendering or update work but SHALL preserve declared binding and freshness semantics.

#### Scenario: Hidden live frame
- **WHEN** a live frame becomes hidden under a suspend-render policy
- **THEN** the system applies its declared data buffering/coalescing behavior and accurately reports freshness when shown again
