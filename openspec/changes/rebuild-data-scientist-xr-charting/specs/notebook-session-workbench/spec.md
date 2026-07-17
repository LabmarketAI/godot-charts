## ADDED Requirements

### Requirement: Immersive analytical workbench boundary
The product SHALL support an immersive analytical-workbench experience connected to Jupyter while keeping notebook/kernel integration outside the pure chart renderer. The Godot addon SHALL consume transport-neutral descriptors and commands; a companion integration SHALL own Jupyter authentication, protocol operations, Python inspection, and authorized execution.

#### Scenario: Use charts without Jupyter
- **WHEN** the addon runs without a notebook companion
- **THEN** local/static plots, frames, compound figures, assets, and supported session-data workflows remain usable and Jupyter-only actions are absent or explicitly unavailable

#### Scenario: Connect a companion
- **WHEN** an authorized Jupyter companion advertises capabilities
- **THEN** notebook objects and permitted actions become available without loading Python, credentials, or notebook protocol logic into plot renderers

### Requirement: Notebook provenance graph
Notebook-connected plots and data SHALL retain resolvable provenance across server/workspace, kernel/session, notebook/document, cell/execution, output, variable/data handle, source plot, transformation, snapshot, frame, and compound view identities where supplied. Users SHALL be able to navigate supported relationships in both directions.

#### Scenario: Trace a plot to its cell
- **WHEN** a user inspects provenance on a notebook-published plot
- **THEN** the workbench identifies its server, kernel, notebook, cell, execution/output, source data, adapter, and local modifications according to permissions

#### Scenario: Find views of a DataFrame
- **WHEN** a user inspects a cataloged DataFrame
- **THEN** the workbench can list active frames, compound views, snapshots, and derived datasets that reference it

### Requirement: Kernel, execution, and output status
The workbench SHALL present kernel busy, idle, starting, restarting, disconnected, and dead states; notebook/cell execution identity and count; output revision and timestamp; errors; stale relationships; and relevant environment/library versions where available. It SHALL NOT present an output as current when its producing kernel, cell, variable, or source revision is known to have changed incompatibly.

#### Scenario: Cell reruns with new output
- **WHEN** a known cell executes again and publishes a replacement plot or data revision
- **THEN** bound frames apply their revision/representation policies and provenance points to the new execution while snapshots remain fixed

#### Scenario: Kernel restarts
- **WHEN** a kernel restart invalidates object handles
- **THEN** affected catalog objects and views become unresolved or stale until identity/schema-safe rebinding succeeds

### Requirement: Capability-gated notebook actions
Notebook actions SHALL be expressed as typed commands against stable targets and advertised capabilities. Baseline access SHALL be read/discover/inspect. Optional actions such as refresh, rerun a known cell, interrupt, restart, declared-parameter update, or pre-registered command execution SHALL require appropriate permission, target identity, preview/confirmation policy, timeout, cancellation, result status, and audit provenance.

#### Scenario: Rerun a known cell
- **WHEN** an authorized user requests rerun for a stable cell identity
- **THEN** the workbench shows target and consequences, submits a typed command after required confirmation, tracks execution status, and associates resulting outputs with the new execution

#### Scenario: Unauthorized restart
- **WHEN** a user without restart capability requests a kernel restart
- **THEN** no command is submitted and the UI communicates the missing permission

### Requirement: No implicit arbitrary code execution
The chart addon SHALL NOT evaluate arbitrary Python code, notebook cells, shell commands, callbacks, or expressions received in plot/data messages. Free-form code execution SHALL NOT be a core chart capability. Any future code-editing or console host SHALL use a separate explicit security and authorization contract.

#### Scenario: Message contains executable code
- **WHEN** a plot, data, asset, or notebook descriptor contains an undeclared executable payload
- **THEN** the addon rejects or treats it as inert text according to schema and emits a security diagnostic

### Requirement: Spatial notebook navigation
The workbench SHALL allow host applications to present searchable and filterable notebooks, cells, outputs, variables/data, plots, frames, compound views, statuses, and relationships as accessible desktop or spatial UI. Navigation SHALL preserve analytical context and SHALL not require mapping every notebook cell to a permanent 3D object.

#### Scenario: Open a cell output in a frame
- **WHEN** a user selects a compatible plot or data output from notebook navigation
- **THEN** they can preview and place it into a new frame or compound slot with provenance and binding policy intact

#### Scenario: Focus producing context
- **WHEN** a user invokes “show source context” on a frame
- **THEN** the workbench focuses the corresponding notebook/cell/data descriptor without changing the chart or executing the cell

### Requirement: Connection and credential safety
The Godot host SHALL provide the user-facing connection and authentication workflow for authorized Jupyter deployments, including deployments reachable only through a private network, VPN, enterprise proxy, gateway, or host-provided network route. Backend protocol operations and secret exchange SHALL remain behind host or companion security adapters rather than plot renderers. The workflow SHALL support deployment-advertised methods such as token, credential broker, system-browser/SSO, device flow, client certificate, or reverse-proxy identity without assuming that every method is available on every Godot platform or WebXR browser. Credentials SHALL use platform-appropriate protected storage or remain ephemeral according to host policy and SHALL NOT be embedded in plot specifications, theme packs, session exports, logs, frame provenance, or ordinary Godot resources. Reconnection SHALL verify backend, server, workspace, kernel, and notebook identity before rebinding objects.

#### Scenario: Connect through a private-network route
- **WHEN** the host exposes an authorized route and authentication adapter for a private Jupyter deployment
- **THEN** Godot presents that connection option, reports route and authentication status without revealing secrets, and discovers resources only after authorization succeeds

#### Scenario: WebXR cannot use a configured authentication method
- **WHEN** an authentication or private-network mechanism is unavailable in the current browser or export target
- **THEN** the connection is marked unavailable with an actionable capability diagnostic rather than attempting an insecure fallback

#### Scenario: Export a spatial session
- **WHEN** a notebook-connected session is exported
- **THEN** it contains reconnectable non-secret references and provenance but excludes tokens, cookies, passwords, and other credentials

### Requirement: Jupyter target discovery and explicit selection
The workbench SHALL discover and present only authorized Jupyter servers, workspaces/projects where provided, notebook documents, and live kernel sessions. Each target SHALL have a stable identity, human-readable label, endpoint or deployment label, availability and authentication state, last-used metadata, and sufficient disambiguating context to distinguish similarly named notebooks. Users SHALL explicitly choose the server/workspace and notebook context used for browsing or new bindings; discovery SHALL NOT silently select a notebook merely because it is the only currently visible target.

#### Scenario: Choose between similarly named notebooks
- **WHEN** two authorized servers or workspaces expose notebooks with the same filename
- **THEN** the chooser displays their server, workspace/project, path, kernel, and status context and binds only the target the user confirms

#### Scenario: No notebook has been selected
- **WHEN** the connection is authenticated but no notebook context is active
- **THEN** the workbench remains in an explicit server/workspace browsing state and does not attribute plots, data objects, or commands to an inferred notebook

### Requirement: Visible active analytical context
The host SHALL expose a persistent, accessible context indicator for the active backend, Jupyter server, workspace/project when supplied, notebook/document, kernel/session, connection state, and permission mode. Frame and catalog provenance SHALL remain independently identifiable even when it differs from the active browsing context. Context indicators SHALL be available in desktop and immersive presentations and SHALL not rely on color alone.

#### Scenario: Inspect the current workspace
- **WHEN** a user asks which workspace or notebook is active
- **THEN** the workbench identifies the backend, server, workspace/project, notebook path, kernel/session, connection status, and effective read/execute permission without exposing authentication material

#### Scenario: View content from another context
- **WHEN** a frame remains bound to notebook A while the active catalog browses notebook B
- **THEN** the frame retains a visible notebook-A provenance cue and commands target notebook A only after normal identity and permission checks

### Requirement: Safe context switching
Switching the active server, workspace, notebook, or kernel SHALL be an explicit, cancellable operation. Before switching, the workbench SHALL identify affected live references, active commands, uncommitted parameter changes, and context-scoped selections. Existing frames SHALL follow a declared policy of retain-original-binding, snapshot, rebind-after-compatible-confirmation, or close; they SHALL NOT silently resolve a same-named object in the new context. The workbench SHALL preserve recent authorized connection profiles as non-secret references and SHALL support returning to a previous context when it remains available.

#### Scenario: Switch notebooks with live frames
- **WHEN** the user changes the active notebook while frames hold live references to the current kernel
- **THEN** the workbench previews the affected bindings and retains, snapshots, or explicitly rebinds each according to confirmed policy

#### Scenario: Restore a session with an unavailable private server
- **WHEN** a saved session references a server that is unreachable or no longer authorized
- **THEN** materialized snapshots remain inspectable, live bindings are marked disconnected, and the host offers reconnection or target replacement without substituting another server automatically

### Requirement: Host-extensible notebook capabilities
The notebook workbench contract SHALL permit future host applications to add editors, terminals, package tools, debuggers, collaboration, or richer execution workflows without making those capabilities mandatory dependencies or allowing them to alter plot semantics outside declared commands and revisions.

#### Scenario: Host adds a code editor
- **WHEN** a future host registers an authorized code-editing capability
- **THEN** existing plot, data, frame, provenance, and revision contracts continue to function without renderer changes
