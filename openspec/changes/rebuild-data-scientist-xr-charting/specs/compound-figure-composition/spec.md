## ADDED Requirements

### Requirement: Multiple views within one frame
A frame SHALL host one retained figure containing one or more stable view identities. Views in a compound figure SHALL share the frame's lifecycle, transform, outer chrome, theme context, and compound export boundary while retaining independently addressable plot content, binding, analytical state, status, and provenance.

#### Scenario: Create a quad plot
- **WHEN** a user chooses the 2×2 composition preset and adds four plots
- **THEN** one frame contains four stable view slots with independently selectable content and one shared frame lifecycle

#### Scenario: Delete one view
- **WHEN** a user removes one view from a compound figure
- **THEN** the configured empty-slot or reflow policy applies without deleting the frame or mutating the remaining view identities and bindings

### Requirement: Source and session composition provenance
The system SHALL accept compound figures authored by a publisher and SHALL allow users to create or modify compound figures locally during a session. It SHALL record source provenance for every view and SHALL distinguish publisher-authored composition from local composition and overrides.

#### Scenario: Receive published subplots
- **WHEN** a source plot message contains a supported multi-view figure
- **THEN** its view hierarchy, authored ordering, layout constraints, shared guides, and link semantics normalize into one compound figure

#### Scenario: Bundle existing session plots
- **WHEN** a user selects several plots or frames and chooses “bundle into frame”
- **THEN** the library previews a local compound layout, preserves each source binding and view state according to the chosen policy, and records that the composition is session-authored

#### Scenario: Reset local layout
- **WHEN** a locally modified published compound figure is reset to source
- **THEN** the publisher's composition is restored without mutating the publisher or losing recoverable local history

### Requirement: Composable layout tree
The figure model SHALL support nested row, column, regular grid, named mosaic with spanning cells, inset, overlay, tab/page, and explicitly authored spatial layout nodes. Layout nodes SHALL support stable slot names, ordering, weights, minimum and ideal sizes, aspect policies, gaps, padding, alignment, guide regions, overflow, and responsive breakpoints.

#### Scenario: Use an asymmetric mosaic
- **WHEN** a layout declares one overview view spanning two rows beside two detail views
- **THEN** deterministic constraint resolution preserves the named slots, span, ordering, gaps, and minimum sizes

#### Scenario: Insufficient frame area
- **WHEN** a resized frame cannot satisfy every view's declared minimum readable size
- **THEN** the explicit overflow policy reflows, paginates, focuses, or reports the constraint conflict rather than silently overlapping or illegibly shrinking views

### Requirement: Per-view bindings and failure isolation
Each view SHALL support its own static plot, live published plot, raw stream, derived view, or snapshot binding and its own representation, revision, pause, freshness, reconnect, and fallback policy. Failure or schema change in one view SHALL NOT invalidate compatible sibling views.

#### Scenario: Mixed live sources
- **WHEN** four quad-plot views subscribe to different update cadences and topics
- **THEN** each view applies its own ordered revisions while the compound layout and unaffected views remain stable

#### Scenario: One source disconnects
- **WHEN** one view's source becomes unavailable
- **THEN** that slot shows its stale/error and last-good state while sibling views continue updating and linked behavior degrades according to policy

### Requirement: Shared scales, axes, and guides
Views MAY share compatible scale domains, axes, legends, colorbars, titles, or guide regions through explicit relationships. The library SHALL validate type, units, transformations, direction, and update ownership before sharing and SHALL deduplicate presentation without erasing per-view provenance.

#### Scenario: Share a longitudinal X axis
- **WHEN** vertically stacked views declare compatible time scales with shared X domain
- **THEN** domain changes remain synchronized and the layout may present one shared axis while each view retains its own Y scale and source identity

#### Scenario: Share incompatible color scales
- **WHEN** two views use incompatible units or transformations for color
- **THEN** the library refuses a shared colorbar or requires an explicit conversion rather than presenting a misleading common legend

### Requirement: Coordinated multi-view interaction
Compound figures SHALL support explicit directional or bidirectional linking of cursor, hover, selection, filter, domain, camera, time, playback, and parameter state where compatible. A linked interaction SHALL identify its originating view and propagated effects and SHALL be undoable when it mutates analytical state.

#### Scenario: Brush-and-link a quad plot
- **WHEN** a user brushes observations in one linked view
- **THEN** compatible sibling views highlight or filter the same source identities according to their declared relationship while unlinked views remain unchanged

#### Scenario: Unlink one view
- **WHEN** a user removes a view from a shared-domain relationship
- **THEN** it retains the declared current or prior local domain and subsequent sibling zooms no longer affect it

### Requirement: Hierarchical selection and manipulation
Input routing SHALL distinguish frame, composition node, view, and view-content scopes. Users SHALL be able to select the frame, one or more views, or plot content; reorder, replace, duplicate, span, resize, focus, maximize, restore, or remove views; and manipulate the outer frame without ambiguous gesture ownership.

#### Scenario: Maximize one subplot
- **WHEN** a user focuses or maximizes one view for inspection
- **THEN** its binding and analytical state remain in the compound figure, sibling views follow the declared hide/context policy, and restore returns to the prior composition

#### Scenario: Drag a view between slots
- **WHEN** composition mode captures a view and drops it into another compatible slot
- **THEN** the preview communicates swap/reorder/replace semantics and commit changes only the composition state

### Requirement: Immersive compound presentation
Compound figures SHALL support a conventional planar layout and MAY expose curved, paged, focus-plus-context, or explicitly spatial presentations. Alternative presentations SHALL preserve authored view identities, ordering, links, data semantics, and a deterministic route back to the authored layout.

#### Scenario: Curve a quad plot in WebXR
- **WHEN** a planar 2×2 figure uses an approved curved presentation for viewing distance
- **THEN** all four views remain identifiable and ordered, shared guides remain truthful, interaction targets remain usable, and reset restores the authored planar arrangement

### Requirement: Compound persistence and export
Session persistence SHALL store the composition tree, view identities, bindings, layout constraints, relationships, local overrides, focus/page state, and source-versus-local provenance. Compound export SHALL preserve the full figure when the target format supports it or SHALL report the exact flattening/splitting fallback.

#### Scenario: Restore a mixed-source quad plot
- **WHEN** a saved session containing a four-view compound frame is reopened
- **THEN** its layout and view identities restore deterministically, available sources reconnect independently, and unavailable views use explicit placeholders

#### Scenario: Split a view into a frame
- **WHEN** a user extracts one view from a compound figure into its own frame
- **THEN** the new frame receives a distinct identity and the selected copy-or-move policy preserves its binding, view state, provenance, and history boundary

### Requirement: Compound performance and accessibility
The library SHALL define budgets for view count, active bindings, marks, guides, labels, interaction targets, layout resolution, and stereo rendering. It SHALL apply per-view visibility, focus, LOD, update coalescing, and label policies without losing status or presenting stale data as current. Every view and slot SHALL have an accessible name, position, status, and navigation order.

#### Scenario: Paginate a dense dashboard
- **WHEN** the active device tier cannot render every compound view at its required fidelity
- **THEN** the declared paging or focus policy reduces work while preserving view status, accessible navigation, binding freshness, and deterministic return to the full layout
