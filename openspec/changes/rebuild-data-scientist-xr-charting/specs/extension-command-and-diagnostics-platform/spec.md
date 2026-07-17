## ADDED Requirements

### Requirement: Versioned extension registries
The platform SHALL provide bounded registries for marks/coordinates, data and plot adapters, backend adapters, message transports, authentication providers, transforms, inspectors, interaction tools, commands, exporters, and theme/asset packs. Extensions SHALL declare stable identifier, version, namespace, capability, dependency manifest, lifecycle, permissions, security class, supported platforms/export tiers, limits, and conformance fixtures.

#### Scenario: Register a community exporter
- **WHEN** a compatible exporter extension is enabled
- **THEN** its actions appear only for supported objects and permissions without altering core plot or session schemas

### Requirement: Dependency-isolated extension contracts
Extensions SHALL integrate through public normalized interfaces, and optional dependency absence or failure SHALL not prevent unrelated core workflows. Third-party internal types SHALL not be serialized into public persisted state except through versioned namespaced metadata with fallback behavior.

#### Scenario: Remove an optional extension
- **WHEN** a session references an unavailable optional tool
- **THEN** core objects remain loadable and the missing capability is represented by a diagnostic or placeholder

### Requirement: Unified command registry
User actions SHALL be represented by stable command identifiers with typed arguments, target and context, availability predicate, permission, confirmation, undo/side-effect policy, progress/cancellation, help metadata, and input bindings. Menus, command palette, keyboard, touch, controller, voice, and contextual affordances SHALL invoke the same commands.

#### Scenario: Find an action without its spatial control
- **WHEN** a user searches the command palette for “snapshot frame”
- **THEN** the same permission-checked command used by frame chrome is discoverable with shortcut and help information

### Requirement: Global discovery and navigation
The host SHALL support permission-filtered search across backends, workspaces, notebooks, cells/outputs, data, plots, streams, frames, compound views, checkpoints, commands, help, and diagnostics with stable result identity, recent/favorite behavior, and context-preserving navigation.

#### Scenario: Search for a DataFrame
- **WHEN** a user selects a DataFrame result from another authorized notebook context
- **THEN** the workbench previews the context switch or opens it according to explicit policy rather than silently changing the active notebook

### Requirement: Production diagnostics surface
Authorized users SHALL be able to inspect normalized specs, compatibility reports, identities/revisions, execution plans, stream lag/drops, protocol status, command progress, render/picking metrics, memory/LOD state, and dependency/extension versions. Diagnostics SHALL distinguish source, adapter, transport, execution, model, and rendering failures.

#### Scenario: Diagnose a mismatched Matplotlib plot
- **WHEN** an imported plot differs from its source
- **THEN** diagnostics identify adapter classifications, approximations/fallbacks, source and adapter versions, normalized paths, and relevant render state

### Requirement: Redacted capture and support bundles
Diagnostics SHALL support bounded event/message capture and deterministic replay references with configurable redaction of credentials, endpoints, data values, queries, paths, and user identities. Support bundles SHALL list their contents before export and require applicable permission.

#### Scenario: Capture a private-network failure
- **WHEN** a user exports a support bundle for an authorized connection failure
- **THEN** it preserves negotiation, timing, status, dependency, and correlation evidence while applying declared endpoint and credential redaction
