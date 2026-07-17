## ADDED Requirements

### Requirement: Separate plot and data sources
The session catalog SHALL distinguish published plot specifications from data objects. Opening a published plot SHALL preserve its representation policy; opening a data object SHALL begin a locally authored plot workflow and SHALL NOT imply a chart type until compatible mappings are selected or confirmed.

#### Scenario: Open a published longitudinal plot
- **WHEN** a catalog entry contains a published line-plot specification
- **THEN** the default action opens that representation with source provenance and follow-source behavior

#### Scenario: Open a longitudinal DataFrame
- **WHEN** a catalog entry contains year and trial-count columns but no plot specification
- **THEN** the library previews compatible mappings and representations and requires confirmation before creating a locally authored plot

### Requirement: Session data descriptors and opaque handles
Every remote data object SHALL be represented by a stable opaque handle and a JSON-safe descriptor containing source session/kernel identity, adapter and library versions, object kind, revision or fingerprint, shape, schema, index or coordinates, semantic and physical types, units where known, null/non-finite summaries, preview, capabilities, permissions, freshness, and provenance. The descriptor SHALL NOT contain executable object references.

#### Scenario: Discover a pandas DataFrame
- **WHEN** the Jupyter adapter advertises a supported pandas DataFrame
- **THEN** the catalog exposes its columns, index summary, dtypes/semantic types, shape, bounded preview, revision, source kernel, and allowed operations without transferring the full table

#### Scenario: Handle expires after kernel restart
- **WHEN** a remote kernel restarts and invalidates a DataFrame handle
- **THEN** bound views enter an explicit unresolved/stale state and may rebind only after identity and schema compatibility checks

### Requirement: Supported Python data adapters
The companion package SHALL adapt supported pandas DataFrame and Series, NumPy arrays, Arrow-compatible tables, xarray objects, and dataframe-interchange objects into the common descriptor and request contract. Library-specific features that cannot be represented SHALL produce path-addressed diagnostics.

#### Scenario: Preserve DataFrame index
- **WHEN** a DataFrame has a named index or MultiIndex used for plotting
- **THEN** the adapter exposes its levels, names, ordering, uniqueness, and reset/materialization options without silently discarding it

#### Scenario: Object dtype requires inspection
- **WHEN** a pandas object column has ambiguous or mixed values
- **THEN** the adapter reports its physical and inferred semantic status, bounded evidence, and conversion requirements rather than declaring an unsafe type silently

### Requirement: Bounded and revision-safe data access
The receiver SHALL request only authorized columns, rows/pages, filters, aggregates, samples, or snapshots through bounded asynchronous operations with cancellation, byte/row/column/time limits, backpressure, and expected-revision checks. Full eager transfer SHALL NOT be required to preview or recommend a plot.

#### Scenario: Preview a large DataFrame
- **WHEN** a DataFrame exceeds the active transfer and rendering budgets
- **THEN** the system fetches bounded schema, statistics, and preview/sample data and clearly identifies that the preview is partial

#### Scenario: Data changes during fetch
- **WHEN** the source revision changes while a snapshot request is in progress
- **THEN** the request fails or completes under an explicit consistency policy and never labels a mixed-revision result as one coherent snapshot

### Requirement: Local plot construction from data
The library SHALL allow a user to create a retained plot by selecting data fields, declarative transforms, encoding channels, marks, scales, guides, interaction parameters, and target frame or compound-view slot. The resulting plot SHALL record the data binding, normalized specification, source revision policy, and session-authored provenance.

#### Scenario: Plot a DataFrame in a new frame
- **WHEN** a user maps `year` to X and `trials` to Y and chooses a line mark
- **THEN** the library creates a locally authored plot bound to the DataFrame under the selected live or snapshot policy and records every mapping choice

#### Scenario: Add a DataFrame view to a quad plot
- **WHEN** the user targets an empty compound-view slot during plot construction
- **THEN** the new plot occupies that slot while retaining its independent data binding, status, and provenance

### Requirement: Explainable compatible-plot recommendations
The library MAY recommend marks, encodings, transforms, and guides from semantic types, cardinality, shape, units, ordering, index/coordinate metadata, and missingness. Recommendations SHALL include reasons and required assumptions, SHALL identify lossy or sampled behavior, and SHALL require user confirmation before persistent creation.

#### Scenario: Recommend a longitudinal plot
- **WHEN** one ordered temporal/year field and one quantitative field are selected
- **THEN** the library may recommend line and point representations and explains ordering, aggregation, missing-value, and duplicate-X assumptions

#### Scenario: Reject a 3D recommendation
- **WHEN** the selected data lacks three meaningful spatial or encoded dimensions
- **THEN** the recommender does not promote an arbitrary 3D chart solely because the renderer supports spatial plots

### Requirement: Live, snapshot, and derived bindings
A data-backed plot SHALL declare `live_reference`, `snapshot`, or `derived` binding semantics. Live references SHALL track compatible revisions; snapshots SHALL identify a fixed materialized revision; derived bindings SHALL retain an inspectable transformation graph, input revisions, execution location, and reproducibility metadata.

#### Scenario: Freeze a live DataFrame plot
- **WHEN** a user snapshots a live DataFrame-backed plot
- **THEN** the frame displays a fixed data revision with timestamp and provenance while the original live binding remains independently recoverable

#### Scenario: Schema changes incompatibly
- **WHEN** a live source removes or changes the type of a mapped column
- **THEN** the plot retains its last-good revision, reports the broken mapping, and requires a compatible rebind or explicit conversion

### Requirement: Safe declarative transformations
Data-backed plots SHALL support capability-negotiated declarative filter, sort, derive, bin, aggregate, group, sample, reshape, and join operations. Transform definitions SHALL be serializable, bounded, validated, and provenance-preserving and SHALL NOT carry arbitrary Python code or expressions outside an approved expression grammar.

#### Scenario: Aggregate trials by year
- **WHEN** duplicate year rows require grouping for a requested plot
- **THEN** the user selects or confirms an aggregation and the derived dataset records the grouping keys, operation, input revision, output schema, and execution location

#### Scenario: Unsupported remote transform
- **WHEN** the Python adapter cannot execute a requested safe transform and the data exceeds local transfer limits
- **THEN** plot creation reports the unavailable capability and alternatives rather than fetching unbounded data or executing arbitrary code

### Requirement: Selection-derived session data
A user SHALL be able to register selected, filtered, aggregated, or currently displayed rows from a chart as a new session data object with stable identity, schema, source-row provenance, transformation history, and live-or-snapshot policy where supported.

#### Scenario: Promote a brush selection
- **WHEN** a user brushes points and chooses “create dataset from selection”
- **THEN** the catalog gains a derived data entry whose rows and predicate resolve to the original source and whose subsequent plotting does not mutate that source

### Requirement: Data status, permissions, and writeback boundary
The UI SHALL expose source identity, revision, freshness, partial/sample state, transformations, permissions, and whether data is remote, cached, materialized, or derived. Read, compute, materialize, publish, and writeback permissions SHALL be distinct. This capability SHALL NOT write to a Python object unless a future authorized writeback capability explicitly permits it.

#### Scenario: Read-only DataFrame
- **WHEN** a user plots a DataFrame exposed with read and aggregate permissions but no writeback permission
- **THEN** local plots and derived datasets are allowed within limits while edits to the source object are unavailable

### Requirement: Future in-session data generation compatibility
Future manual, computed, simulated, imported, or procedurally generated session data SHALL register through the same descriptor, revision, capability, provenance, request, and binding contracts as remote Python data so plot construction remains source-independent.

#### Scenario: Future generated table
- **WHEN** a future session generator registers a local table
- **THEN** the existing catalog, plot builder, snapshot, derived-data, compound-view, persistence, and permission workflows can consume it without a generator-specific chart path

### Requirement: Future external-data acquisition boundary
The architecture SHALL permit future file pickers, uploads, URLs, databases, object stores, and other acquisition providers to submit capability-scoped import requests to authorized processors. Acquisition providers and processors SHALL register successful outputs through the same session data descriptor and SHALL remain outside chart renderers and plot specifications.

#### Scenario: Select an Excel workbook
- **WHEN** a future desktop, native XR, or WebXR file selector supplies an authorized `.xls` or `.xlsx` reference and the user chooses a Python/Jupyter processor
- **THEN** the workflow can inspect workbook metadata, preview available sheets/ranges, confirm import options, and register resulting tables as session data without adding Excel parsing to the Godot chart core

#### Scenario: Browser file versus remote kernel
- **WHEN** WebXR selects a local browser file but the processor runs in a remote Jupyter session
- **THEN** an authorized bounded upload/staging flow provides processor access without treating the browser-local path as remotely readable

#### Scenario: Unsupported import format
- **WHEN** no authorized processor advertises support for a selected source format
- **THEN** the acquisition workflow reports the missing capability and does not register a misleading or partial dataset

### Requirement: Safe staged import lifecycle
A future import workflow SHALL separate selection, metadata inspection, processor and option selection, preview, confirmation, materialization, catalog registration, cancellation, and cleanup. It SHALL record source checksum/reference, processor and library versions, import options, selected sheet/table/range, warnings, output schema, permissions, and provenance and SHALL bound bytes, rows, columns, archives, memory, and processing time.

#### Scenario: Workbook contains multiple sheets
- **WHEN** a processor discovers several sheets or named tables
- **THEN** the user can preview and choose outputs before materialization and every registered dataset records its workbook and sheet/table provenance

#### Scenario: Import is cancelled
- **WHEN** a user cancels during upload, processing, or preview
- **THEN** no catalog entry is committed and temporary staged resources follow the declared cleanup policy

#### Scenario: Workbook contains active content
- **WHEN** an Excel processor detects macros, external links, or another disallowed active feature
- **THEN** policy blocks or sanitizes processing with an explicit security diagnostic rather than executing the content implicitly

### Requirement: Data-session persistence and recovery
Session persistence SHALL store descriptors, handles as reconnectable references rather than assumed-valid pointers, plot mappings, transformations, snapshots according to storage policy, last-good metadata, and unresolved-source state. Restoring a session SHALL verify source identity and revision before reconnecting live data.

#### Scenario: Restore a DataFrame-backed plot
- **WHEN** a session is reopened while the original Jupyter kernel is available
- **THEN** the binding verifies kernel/object identity, schema, and revision policy before resuming and otherwise remains visibly unresolved with rebind options
