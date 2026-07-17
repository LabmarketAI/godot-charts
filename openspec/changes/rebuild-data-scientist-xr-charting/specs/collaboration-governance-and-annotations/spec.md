## ADDED Requirements

### Requirement: Collaboration-compatible identities and state
Core session, frame, view, selection, parameter, command, annotation, checkpoint, and history contracts SHALL support optional actor identity and private, shared, or presentation scope without requiring collaboration in single-user deployments.

#### Scenario: Open a single-user session
- **WHEN** no collaboration provider is installed
- **THEN** all core workflows function with local ownership and no network collaboration dependency

### Requirement: Presence and shared manipulation
An optional collaboration adapter SHALL advertise presence, shared/private pointers and selections, frame manipulation ownership or leases, presenter/follow mode, comments, and shared spatial-anchor capabilities. Conflicting manipulation SHALL be prevented or resolved through declared policies rather than last-writer ambiguity.

#### Scenario: Two users reach for one frame
- **WHEN** a participant holds an active manipulation lease
- **THEN** other participants receive visible ownership state and cannot unknowingly commit a conflicting transform

### Requirement: Concurrent history and reconciliation
Collaborative sessions SHALL define authoritative state, event ordering, reconnect/late-join synchronization, conflict policy, per-user versus shared undo, offline edits, and incompatible revision handling. Remote computational commands SHALL never be replayed merely to reconcile visual state.

#### Scenario: User rejoins after disconnect
- **WHEN** a participant reconnects with stale spatial state
- **THEN** the collaboration adapter reconciles declared shared state and preserves or discards private state according to policy without rerunning notebook commands

### Requirement: Analytical annotations and stories
Users SHALL be able to attach notes, callouts, measurements, reference guides, tags, status, and links to stable data, mark, region, axis, view, frame, checkpoint, or provenance identities. Annotations SHALL record author, time, scope, permissions, source revision, and orphan/rebind behavior. Ordered story/tour steps MAY reference checkpoints and viewpoints without mutating their evidence.

#### Scenario: Return to annotated evidence
- **WHEN** a user follows an annotation attached to a checkpointed region
- **THEN** the workbench restores or clearly approximates the authorized analytical context and identifies unavailable source revisions

### Requirement: Resource and data governance
Host and backend adapters SHALL support distinct user/group/project/tenant, resource viewer/editor/owner, dataset/field/row policy, command, export, annotation, and sharing decisions where supplied. Effective permission SHALL remain attached through derived data, selections, snapshots, caches, and exports and SHALL not be widened by local composition.

#### Scenario: Derive a chart from restricted rows
- **WHEN** a user creates a derived plot from row-filtered data
- **THEN** the derived object retains the applicable access and export constraints and cannot disclose excluded rows through inspection or aggregation

### Requirement: Audit, retention, and deletion
Security-relevant connection, access, command, export/share, permission, collaboration, and deletion events SHALL be available to an authorized host audit provider with actor, target, context, outcome, and correlation identifiers but no unnecessary protected payload. Retention, legal hold, revocation, ownership transfer, and deletion behavior SHALL be host policy and SHALL distinguish local artifacts from remote resources.

#### Scenario: Delete a shared checkpoint
- **WHEN** an authorized owner deletes or revokes a checkpoint
- **THEN** hosted access follows retention/revocation policy, audit records the action, and unrelated source data or notebook objects are not deleted implicitly
