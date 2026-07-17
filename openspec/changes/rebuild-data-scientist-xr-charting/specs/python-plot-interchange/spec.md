## ADDED Requirements

### Requirement: Transport-independent plot message
The system SHALL accept a JSON-compatible `plot-message` envelope containing `schema`, `message_id`, `operation`, `plot_id`, `revision`, `created_at`, `producer`, `payload`, and optional `routing`, `diagnostics`, and `attachments` fields. The plot payload SHALL be a normalized plot specification for `replace` operations or a bounded patch for `patch` operations; message-bus-specific delivery metadata SHALL remain outside the normalized plot specification.

#### Scenario: Receive a complete plot
- **WHEN** a valid `replace` message with a newer revision arrives for a plot identifier
- **THEN** the receiver validates and atomically installs the normalized figure while exposing its producer and adapter provenance

#### Scenario: Replay a duplicate
- **WHEN** a previously applied `message_id`, `plot_id`, and revision is delivered again
- **THEN** the receiver treats it idempotently and does not duplicate layers, data, or events

#### Scenario: Receive an out-of-order patch
- **WHEN** a patch references a base revision other than the receiver's active revision
- **THEN** the receiver rejects or defers it with a structured resynchronization diagnostic and does not partially mutate the plot

### Requirement: Versioned Python adapter contract
The companion Python package SHALL accept supported plotting objects from Matplotlib, Seaborn, Plotly, Altair/Vega-Lite, and Bokeh and SHALL emit the same normalized plot-message schema with source library/version, adapter/version, object type, stable plot/layer identifiers, and conversion diagnostics.

#### Scenario: Adapt a live Matplotlib figure
- **WHEN** a caller passes a supported `matplotlib.figure.Figure` containing multiple axes and supported artists
- **THEN** the adapter emits one normalized figure preserving subplot structure, data coordinates, scales, guides, styles, and source identities within declared compatibility tolerances

#### Scenario: Unsupported object type
- **WHEN** a caller passes an unsupported Python plotting object
- **THEN** the adapter returns a typed unsupported-object error without publishing a partial plot unless fallback was explicitly requested

### Requirement: Explicit semantic fidelity
Every adapter SHALL classify each converted source feature as `native`, `approximated`, `raster-fallback`, or `unsupported`, SHALL attach a path-addressed diagnostic for non-native conversion, and SHALL NOT silently reinterpret data, scales, stacking, transforms, or coordinate systems.

#### Scenario: Unsupported custom Matplotlib artist
- **WHEN** a figure contains a custom artist for which no semantic adapter is registered
- **THEN** the result identifies the artist and location as unsupported and either omits it under an explicit partial policy or uses the requested visual fallback

#### Scenario: Visual fallback
- **WHEN** raster fallback is explicitly enabled for an unsupported view
- **THEN** the message identifies the view as non-semantic, provides bounded image dimensions and accessible fallback text, and disables datum-level interaction for that view

### Requirement: Source-specific semantic extraction
The adapters SHALL use public source-library output contracts where available: validated Plotly figure JSON, versioned Altair/Vega-Lite JSON, and Bokeh document/standalone JSON. The Matplotlib adapter SHALL extract supported semantics from public figure, axes, container, artist, scale, guide, and transform APIs; the Seaborn adapter SHALL initially compile to and extract from its Matplotlib representation while retaining available Seaborn provenance.

#### Scenario: Adapt Plotly JSON
- **WHEN** a supported Plotly figure contains Cartesian and 3D traces
- **THEN** the adapter maps supported traces and layout scenes into normalized layers and views and records the originating Plotly version

#### Scenario: Import source controls
- **WHEN** a supported Plotly slider, animation control, camera, relayout action, or restyle action maps safely to normalized parameters
- **THEN** the adapter emits analytical parameters and control bindings that Godot may present as desktop or world-space controls without executing source callbacks

#### Scenario: Adapt Vega-Lite composition
- **WHEN** an Altair chart serializes to a supported layered, faceted, or concatenated Vega-Lite specification
- **THEN** the adapter preserves its view composition, inline or named data, supported transforms, encodings, scales, and guides

#### Scenario: Adapt Bokeh data sources
- **WHEN** supported Bokeh glyph renderers reference shared column data sources
- **THEN** the adapter preserves shared data identity and supported selections without requiring BokehJS in Godot

### Requirement: Safe portable serialization
The interchange SHALL NOT accept pickle, Python bytecode, arbitrary callbacks, HTML/JavaScript execution, Godot resource paths supplied by remote producers, or implicit external data fetches. Receivers and adapters SHALL enforce configurable limits for envelope bytes, rows, columns, nesting, strings, images, layers, views, and patch operations before allocation-heavy rendering.

#### Scenario: Pickled figure payload
- **WHEN** a message contains or declares a pickled Python object
- **THEN** the receiver rejects it before deserialization and emits a security diagnostic

#### Scenario: Vega-Lite URL data
- **WHEN** a source specification references external URL data and external fetching is not explicitly enabled by trusted policy
- **THEN** the adapter rejects the reference or requires the producer to inline/attach the resolved data

#### Scenario: Oversized message
- **WHEN** an envelope exceeds a configured resource limit
- **THEN** it is rejected before plot mutation with the violated limit and observed size reported

### Requirement: Data and interaction identity across updates
The producer SHALL assign stable row, layer, view, and plot identities when source semantics permit, and the receiver SHALL use them to preserve selection, linkage, and inspection state across compatible revisions. When identity cannot be preserved, the message SHALL declare the reset scope.

#### Scenario: Stream updated Matplotlib line data
- **WHEN** a producer republishes a line with the same plot/layer identity and an appended data revision
- **THEN** the receiver updates that layer and preserves compatible view and selection state without rebuilding unrelated views

### Requirement: Adapter conformance fixtures
Each supported source-library/version combination SHALL have executable object-to-message fixtures and semantic assertions for supported chart types, plus visual comparison tolerances where semantics alone are insufficient.

#### Scenario: Source library upgrade
- **WHEN** CI tests a newly supported plotting-library version
- **THEN** all required fixtures pass or the compatibility matrix records the precise regression before release

### Requirement: Godot-native interaction augmentation
An imported plot SHALL permit local Godot interaction parameters and control bindings to be added without modifying or republishing the source Python object, and SHALL preserve whether each control originated from the source adapter or the Godot consumer.

#### Scenario: Add a slice handle to Matplotlib 3D output
- **WHEN** a Matplotlib 3D surface is imported without a source slider and the Godot consumer binds a world-space slice handle
- **THEN** the local handle controls normalized slice state while the imported source figure and provenance remain intact
