## ADDED Requirements

### Requirement: Session-wide typed parameters
The session SHALL support named typed parameters with stable identity, value type, domain, units, default, current committed value, optional preview value, validation, provenance, sensitivity, permission, and serialization policy. Parameters MAY bind to plots, scales, filters, transformations, queries, titles, compound views, and authorized backend commands without copying values into unrelated specifications.

#### Scenario: Change a shared time range
- **WHEN** a user commits a session time-range parameter bound to several views
- **THEN** every compatible binding updates through its declared execution and revision policy while incompatible or unauthorized bindings report their status

### Requirement: Parameter sources and dependencies
Parameters SHALL support fixed, enumerated, query-backed, derived, and host-provided values plus explicit dependency graphs. Refresh, debounce, cancellation, cycle detection, empty/error states, sensitive-value handling, and option identity SHALL be deterministic.

#### Scenario: Update a chained parameter
- **WHEN** changing a project parameter invalidates the options for a dataset parameter
- **THEN** dependent options refresh with cancellation and the prior selection is retained only if its stable identity remains valid

### Requirement: Immutable analytical view checkpoints
Users SHALL be able to capture a named immutable view checkpoint containing referenced data/plot revisions; backend and adapter provenance; filters, selections, parameters, transforms, scale domains, camera, slices, thresholds, visible layers, compound layout, frame transforms, theme/assets, annotations, and active context as applicable. Missing or nonportable components SHALL be declared.

#### Scenario: Restore a prior analytical moment
- **WHEN** a user opens a checkpoint after live sources have advanced
- **THEN** materialized state restores exactly where available and unresolved live references remain explicit rather than silently using current data

### Requirement: Bookmarks, comparisons, and deep links
The host SHALL support bookmarks or links to permitted session objects, contexts, and checkpoints with explicit inclusion, expiration, authorization, and sensitive-parameter policy. Users SHALL be able to compare checkpoints without mutating either source state.

#### Scenario: Share a filtered view internally
- **WHEN** a user creates an authorized deep link to a checkpoint
- **THEN** the recipient receives the intended context and analytical state subject to their own permissions, without credentials or excluded sensitive values in the URL

### Requirement: Transactional analytical history
Parameter commits, linked filters, selection-derived datasets, view changes, and frame/layout commands SHALL participate in declared transaction boundaries with deterministic undo/redo, cancellation, and checkpoint behavior. Remote side effects SHALL disclose whether they are reversible.

#### Scenario: Undo a coordinated change
- **WHEN** one committed parameter changes several linked views
- **THEN** undo restores the prior coherent session parameter and dependent view state rather than undoing each frame independently
