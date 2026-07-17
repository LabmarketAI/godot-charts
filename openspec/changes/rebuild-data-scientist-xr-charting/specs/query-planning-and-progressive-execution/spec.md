## ADDED Requirements

### Requirement: Declarative execution planning
Every nontrivial data request or transformation SHALL be representable as a declarative plan whose operations, inputs, output schema, estimates, permissions, limits, approximation policy, and provenance are inspectable. The host SHALL choose among local Godot, companion/kernel, database/query engine, remote analytical service, or remote-render execution only from advertised capabilities and policy.

#### Scenario: Push down a large aggregation
- **WHEN** a remote source can aggregate a large dataset without transferring its rows
- **THEN** the planner executes the compatible bounded aggregation remotely and records its location and input revision

### Requirement: Cost, quotas, and confirmation
Adapters SHOULD provide row, byte, time, memory, compute, and result estimates or explicit unknown status. Host policy SHALL apply per-operation, source, user, and session limits and SHALL require confirmation or refusal for operations exceeding configured thresholds.

#### Scenario: Query cost is unexpectedly large
- **WHEN** a requested operation exceeds an interactive threshold
- **THEN** the workbench presents the estimate and alternatives such as filtering, aggregation, sampling, snapshotting, or remote rendering before execution

### Requirement: Progressive and approximate results
Plans MAY return schema-first, partial, sampled, aggregated, level-of-detail, or progressively refined results only when each revision declares completeness, approximation method, confidence/error information where available, and replacement relationship. Approximate results SHALL not masquerade as exact results.

#### Scenario: Refine a spatial point cloud
- **WHEN** an approved plan streams coarse then finer levels of detail
- **THEN** the view remains interactive, labels the current approximation, preserves compatible selections, and atomically replaces superseded levels

### Requirement: Cancellation, supersession, and isolation
Execution SHALL support deadline, cancellation, supersession, bounded concurrency, backpressure, and failure isolation. Late or partial results SHALL satisfy the initiating revision and parameter preconditions before installation.

#### Scenario: User changes a filter during execution
- **WHEN** a new committed filter supersedes the active plan
- **THEN** the old plan is cancelled where possible and its late output cannot overwrite the newer result

### Requirement: Cache identity and invalidation
Cached results SHALL identify normalized plan, input revisions, permissions/tenant scope, backend/environment, adapter versions, approximation, and expiration. Authorization changes, source revisions, environment incompatibility, or policy changes SHALL invalidate or quarantine affected entries.

#### Scenario: Reuse a permitted cached aggregate
- **WHEN** an equivalent plan with matching inputs and authorization is requested
- **THEN** the cache may satisfy it while preserving original execution provenance and current freshness status

### Requirement: Remote rendering boundary
Remote rendering MAY be used for data too large or specialized for local Godot rendering, but SHALL declare loss of local semantics, supported picking/interaction, image/depth/geometry transport, latency, resolution, camera control, and fallback. It SHALL not be reported as native retained marks when only pixels are available.

#### Scenario: Remote volume rendering
- **WHEN** a backend supplies interactive rendered frames but not local geometry
- **THEN** Godot exposes only negotiated camera and inspection capabilities and visibly distinguishes the remote-render view from a native semantic plot
