## ADDED Requirements

### Requirement: Backend-neutral analytical session model
Core workbench contracts SHALL identify a backend, computational session, optional document, optional execution unit, output, data/object handle, artifact, environment, capability, status, and command without requiring Jupyter-specific server, kernel, notebook, cell, or variable semantics. Adapters SHALL map supported backend concepts into this model and SHALL explicitly omit unsupported levels.

#### Scenario: Map Jupyter concepts
- **WHEN** the initial Jupyter adapter registers a notebook session
- **THEN** it maps server, kernel, notebook, cell, output, variable/data handle, environment, and command identities into generic contracts while retaining Jupyter-specific details in namespaced metadata

#### Scenario: Backend has no document concept
- **WHEN** a future database or streaming backend exposes sessions and datasets but no notebook-like document
- **THEN** its plots and data remain usable without fabricating a document or execution-unit identity

### Requirement: Discoverable adapter capabilities
Every computational backend adapter SHALL advertise its identifier/version, supported object and artifact kinds, discovery scopes, hierarchical target levels, data requests, streaming, file acquisition, provenance depth, lifecycle/status, commands, authentication boundary and methods, network-route requirements, limits, and optional extensions. Core UI SHALL derive available connection, target-selection, and analytical workflows from capabilities rather than backend-name conditionals.

#### Scenario: Read-only backend
- **WHEN** an adapter advertises discovery and data access but no execution commands
- **THEN** cataloging and plotting remain available while rerun, interrupt, restart, parameter mutation, and writeback actions are absent

#### Scenario: Backend exposes multiple target levels
- **WHEN** an adapter advertises deployment, workspace/project, document, and computational-session discovery
- **THEN** the host can present those levels with stable identities and active-context status without assuming Jupyter-specific names

### Requirement: Host-mediated connection profiles
Backend connections SHALL use a host-mediated profile containing stable backend and deployment identity, display metadata, non-secret route configuration, supported authentication-method identifiers, capability cache policy, and last-used context references. Secret material and privileged network operations SHALL remain in platform, host, proxy, or companion security providers. Profiles SHALL be portable only to the extent allowed by host policy and SHALL degrade explicitly when a route or authentication provider is unavailable.

#### Scenario: Reuse a known deployment
- **WHEN** a user chooses a previously configured private deployment
- **THEN** the host resolves its approved route and authentication provider, revalidates identity and capabilities, and never treats cached authorization as proof of current access

### Requirement: Namespaced backend extensions
Backend-specific metadata and commands SHALL use versioned namespaced extensions and SHALL NOT redefine core plot, data, frame, binding, provenance, permission, revision, or status semantics. Unknown optional extensions SHALL be preserved or ignored according to policy without invalidating the generic object.

#### Scenario: Unknown adapter extension
- **WHEN** a session descriptor contains an optional extension unknown to the Godot client
- **THEN** generic catalog, plotting, provenance, and status behavior continues and the unsupported extension is diagnosed without arbitrary execution

### Requirement: Adapter conformance and selection gate
An official backend adapter SHALL pass common fixtures for identity, discovery, data and plot interchange, revisions, streaming where supported, provenance, permissions, status/reconnect, command safety, limits, credential handling, and session export. Adoption of a backend after Jupyter SHALL require a separate proposal documenting user demand, supported workflows, deployment, maintenance, and compatibility scope.

#### Scenario: Evaluate a future backend
- **WHEN** a candidate R, Julia, database, workflow, or hosted-analysis adapter is proposed
- **THEN** it is not declared officially supported until its follow-up OpenSpec change and applicable conformance fixtures pass

### Requirement: Jupyter-first without Jupyter lock-in
The first production adapter MAY prioritize Jupyter-specific workflows and terminology in its presentation, but core persisted state, plot/data messages, frames, compound figures, asset packs, and session exports SHALL remain valid without that adapter and SHALL use generic identities plus optional Jupyter extensions.

#### Scenario: Reopen without Jupyter adapter
- **WHEN** a session containing Jupyter-derived snapshots is opened with no Jupyter adapter installed
- **THEN** materialized plots and data remain inspectable with provenance while live references and Jupyter actions are explicitly unavailable
