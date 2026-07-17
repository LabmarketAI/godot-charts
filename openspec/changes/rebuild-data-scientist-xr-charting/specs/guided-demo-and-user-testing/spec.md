## ADDED Requirements

### Requirement: Purpose-built public demo package
The project SHALL ship a small public demo package that teaches the product's core analytical mental model and exercises only released public contracts. The package SHALL separate a minimal backend, recorded fixtures, a standard-Godot project, example notebooks, user-study materials, and a five-minute quickstart. The default path SHALL NOT require an external Jupyter installation, cloud account, private network, XR headset, .NET editor, or arbitrary code execution.

#### Scenario: First clean demo run
- **WHEN** a new user follows the documented default quickstart in a clean supported environment
- **THEN** they can start the local demo backend, run the Godot scene, choose the local demo context, receive a chart, and begin the tutorial without configuring external infrastructure

#### Scenario: Demo uses a private API
- **WHEN** a demo feature cannot be implemented through released addon, adapter, message, and asset contracts
- **THEN** the release gate fails or the missing public contract is proposed and implemented before the demo depends on it

### Requirement: Minimal contract-faithful backend
The demo SHALL provide a bounded backend that implements the same backend-neutral discovery, capability, identity, permission, status, catalog, plot-message, data-object, command, and reconnect contracts as production adapters. It SHALL expose at least two distinguishable workspaces/projects, similarly named notebooks, DataFrame-like objects, published plots, a stream, kernel-like lifecycle states, and read-only versus authorized-action modes. It SHALL NOT accept arbitrary code from Godot or introduce a private demo transport schema.

#### Scenario: Disambiguate duplicate notebook names
- **WHEN** two demo workspaces expose notebooks with the same filename
- **THEN** the Godot chooser presents server/workspace/path/kernel context and binds only the explicitly confirmed notebook identity

#### Scenario: Exercise permission boundaries
- **WHEN** the demo switches from authorized-action mode to read-only mode
- **THEN** discovery and inspection remain available while execution-capable commands disappear or report their unavailable permission without backend-name conditionals

### Requirement: Deterministic replay and optional live Jupyter modes
The default demo backend SHALL replay checked-in, schema-validated message and status fixtures with stable identities, controllable time, pause, step, restart, and failure injection. An optional live mode MAY create real supported Python plotting, pandas, and Qiskit objects through the companion adapter, but both modes SHALL expose the same Godot-facing contracts and comparable analytical scenarios.

#### Scenario: Replay the tutorial in CI
- **WHEN** the recorded demo sequence runs with its deterministic clock
- **THEN** messages, revisions, identities, expected user-visible states, and acceptance assertions are reproducible without network access or a Python kernel

#### Scenario: Switch from replay to Jupyter
- **WHEN** an advanced user selects the optional live Jupyter backend
- **THEN** the Godot scene requires no renderer or workflow-specific changes and visibly identifies the new backend/context

### Requirement: Representative analytical fixtures
The demo fixture set SHALL include a streaming line chart, row-inspectable scatter plot, related histogram, genuinely spatial surface or point view, imported compound figure, and Qiskit circuit. It SHALL include at least one approximated, raster-fallback, or unsupported source feature with a visible compatibility diagnostic. Related charts and data SHALL preserve identities needed for selection, linkage, provenance, revisions, and snapshots.

#### Scenario: Inspect cross-view provenance
- **WHEN** a user selects a row represented in the scatter plot and related histogram
- **THEN** the demo can show its source data identity, related selections, producing notebook context, adapter, and current revisions

### Requirement: Focused onboarding scene
The primary demo scene SHALL be a visually restrained analytical studio rather than a general data-room application. It SHALL provide accessible connection/context, catalog, chart workspace, provenance/data inspection, help, and diagnostics surfaces. It SHALL support desktop input first and the same normalized workflows through native XR and WebXR capability adapters where available.

#### Scenario: Identify current context
- **WHEN** a user views the connection/context surface at any tutorial step
- **THEN** it identifies the active backend, server, workspace/project, notebook, kernel/session, connection state, and effective permission without exposing secrets or relying on color alone

#### Scenario: Continue without XR
- **WHEN** no XR capability is available
- **THEN** every required tutorial task remains completable through documented mouse, keyboard, touch, or accessible desktop controls

### Requirement: Guided analytical curriculum
The demo SHALL provide a restartable, dismissible curriculum that teaches analytical intent as well as control operation. It SHALL cover context selection; published-plot inspection and provenance; plotting an existing data object; chart-domain interaction and reset; frame manipulation; linked and compound views; embodied spatial-chart entry, navigation, inspection, and return; streaming, snapshot, disconnect, and reconnect; and safe notebook-context switching with mixed-context frames.

#### Scenario: Distinguish chart and frame manipulation
- **WHEN** the curriculum asks a user to zoom a chart and then move its frame
- **THEN** visible modes, feedback, undo, and reset allow the user to complete both actions without treating the data-domain change as a frame transform

#### Scenario: Switch context with an existing frame
- **WHEN** the user switches to the second similarly named notebook while a live or snapshot frame from the first remains visible
- **THEN** the tutorial explains the frame's retained source context and verifies that no same-name implicit rebinding occurred

### Requirement: Layered training and help
Training SHALL include concise first-run guidance, contextual analytical-task prompts, input hints, short demonstrations where appropriate, unavailable-capability explanations, visible undo/reset, searchable help or commands, a glossary, and textual alternatives to spatial instructions. Experienced users SHALL be able to dismiss guidance without losing access to help or resetting analytical state.

#### Scenario: Explain an unavailable action
- **WHEN** an action is unavailable because of permission, backend capability, input device, disconnected state, or unsupported source semantics
- **THEN** help identifies the reason and an available alternative without presenting the condition as a generic failure

### Requirement: Privacy-preserving user-study instrumentation
The demo SHALL support opt-in, documented research instrumentation that records bounded interaction events such as task state, completion, elapsed time, help use, mode errors, undo/reset, failed selection, context changes, and recovery outcome. It SHALL NOT record credentials, tokens, private endpoints, raw notebook contents, arbitrary chart values, source code, or personally identifying data by default. Event schemas, retention, export, deletion, and local-versus-remote collection policy SHALL be explicit.

#### Scenario: Decline research collection
- **WHEN** a participant declines instrumentation
- **THEN** the complete demo and curriculum remain usable and no research event stream is transmitted or persisted beyond operational logs required and disclosed by the local application

#### Scenario: Export a study session
- **WHEN** an authorized researcher exports consented study results
- **THEN** the artifact contains declared task and interaction events with participant pseudonym or study identifier and excludes protected analytical and authentication content

### Requirement: User-testing protocols and success measures
The repository SHALL maintain repeatable five-minute first-impression, fifteen-minute guided-workflow, and longer open-analysis study protocols with participant profile, facilitator script, task definitions, observation rubric, interview prompts, accessibility/comfort checks, and success thresholds. Baseline measures SHALL include context identification, published-plot versus data-object understanding, datum provenance, chart-versus-frame manipulation, linked-view creation, disconnect recovery, safe context switching, and spatial-entry orientation.

#### Scenario: Evaluate a release candidate
- **WHEN** a release candidate undergoes formative testing with representative data scientists
- **THEN** findings are recorded against versioned tasks and thresholds, severe comprehension or safety failures block or revise the affected workflow, and raw participant data remains governed by the study policy

### Requirement: Demo as executable release evidence
The same recorded fixtures and public demo scene SHALL support documentation, screenshots, smoke tests, interaction replay, adapter conformance, and user testing to avoid a presentation-only implementation. CI SHALL verify clean startup, tutorial-critical state transitions, accessibility fallbacks, replay determinism, disconnect recovery, and representative desktop/WebXR performance tiers.

#### Scenario: Tutorial behavior regresses
- **WHEN** a public API, dependency, schema, adapter, or interaction change breaks a tutorial-critical workflow
- **THEN** automated demo acceptance fails before release and reports the affected contract and lesson
