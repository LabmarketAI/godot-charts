## 1. Baseline and Product Decisions

- [ ] 1.1 Inventory every public node, resource, property, signal, data shape, install path, known consumer, and demo-owned dependency.
- [ ] 1.2 Add reproducible legacy smoke scenes and capture correctness, lifecycle, memory, and desktop/stereo performance baselines.
- [ ] 1.3 Score each subsystem `keep`, `adapt`, `rewrite`, or `remove` with supporting tests or measurements and an owner-approved decision record.
- [ ] 1.4 Interview or observe representative data scientists completing matplotlib/R comparison workflows and turn findings into prioritized acceptance examples.
- [x] 1.5 Record the pure typed-GDScript addon decision, select the standard Godot version floor, and benchmark only the representative workloads that could justify a future optional GDExtension accelerator.
  - Evidence: the M1 preview is pure typed GDScript, pins official standard Godot 4.6.3 as its floor, and reports measured retained scatter-update and bounded table-refresh timings without introducing an accelerator.
- [ ] 1.6 Define MVP chart types, transformations, dataframe interchange path, desktop platforms, XR runtimes, accessibility targets, and measurable performance tiers.
- [ ] 1.7 Define the supported-version and feature compatibility matrix for Matplotlib, Seaborn, Plotly, Altair/Vega-Lite, and Bokeh from representative real plots.
- [ ] 1.8 Define the dependency-first scorecard and decision-record template covering semantic fit, maintenance, license, security, API stability, Godot/WebXR/platform compatibility, binaries, transitive dependencies, size, performance, testability, and fallback.
- [ ] 1.9 Survey the Godot Asset Library and maintained upstream ecosystems for rendering, XR interaction, UI, networking/message buses, authentication/browser flows, serialization/schema validation, tables, layout, graph algorithms, persistence, testing, and asset pipelines; record `adopt`, `wrap`, `optional integration`, or `build minimal` decisions before implementation tasks begin.

## Milestone M1. Architectural Spine

M1 is the first implementation gate. It SHALL remain deliberately narrow: one recorded Python-originated scatter plot and its bounded table arrive through the normalized session protocol, render incrementally in a clean standard-Godot typed-GDScript project, preserve stable row identity, support inspection and linked selection, survive a compatible replacement revision, expose diagnostics/provenance, and replay deterministically in automated tests. M1 does not require live Jupyter authentication, a network message-bus choice, the full chart catalog, native GIS packages, production XR assets, or a headset.

- [ ] M1.1 Complete the legacy audit and dependency scorecards needed by this slice; record keep/adapt/rewrite/remove and adopt/wrap/optional/build-minimal decisions.
  - Initial evidence: `legacy-audit.md` and `dependency-scorecard.md`. Public API inventory, measurements, version pins, and owner approval remain open.
- [ ] M1.2 Establish clean pure-model, Godot-renderer, input-intent, protocol/replay, and optional-integration boundaries plus a standard-Godot CI fixture with no .NET or native runtime dependency.
  - Started: the protocol/replay module runs in a temporary standard-Godot project through `scripts/test-m1-contract.sh`; model, renderer, input, optional-integration skeletons and CI remain open.
- [x] M1.3 Publish the minimum versioned schemas and golden fixtures for session handshake/capabilities, plot-message replacement, bounded table request/result, row identity, selection, provenance, diagnostics, and replacement revision.
  - Evidence: Draft 2020-12 schemas and generated positive, negative, compatible-revision, and identity-reset fixtures live under `addons/godot-charts/schemas/m1/` and `tests/m1/fixtures/`.
- [x] M1.4 Produce one deterministic Python-side fixture from a supported Matplotlib scatter plot and DataFrame-like source, including missing values and stable row/layer/view/plot identities.
  - Evidence: `tools/m1/generate_fixture.py` uses pinned Matplotlib/pandas dependencies and preserves a missing table row that Matplotlib omits from rendered marks.
- [x] M1.5 Implement deterministic in-process recorded replay with ordering, duplicate handling, revision checks, bounded limits, pause/step/restart, and no network or live-kernel requirement.
  - Evidence: typed-GDScript replay and headless tests cover exact sequencing, gaps, duplicates, stale revisions, byte/row/column limits, pause/step/restart, compatible selection preservation, declared identity reset, atomic rejection, and deterministic restart.
- [x] M1.6 Implement the minimum typed-GDScript retained figure/view/layer model, continuous/categorical scales, axes/guides, validation, serialization, and incremental diff contract required by the fixture.
  - Evidence: scene-independent classes under `addons/godot-charts/core/` normalize replayed plot messages atomically; headless tests cover table and row identity, missing values, linear map/inversion, categorical mapping, retained guides, semantic mapping rejection, deterministic serialization, and table-only versus identity-breaking diffs.
- [x] M1.7 Render the scatter plot incrementally in standard Godot with stable picking identities, bounded resource lifecycle, readable inspection, missing-value behavior, and no destructive full-tree rebuild on a compatible update.
  - Evidence: `renderers/scatter_renderer_3d.gd` retains one `MultiMeshInstance3D` and `MultiMesh`, updates instance transforms/colors in place, omits only rows missing positional values, and resolves deterministic primitive identities to plot/view/layer/dataset/row metadata and inspection values. Headless tests repeat compatible updates without node or resource replacement or scene-tree growth.
- [x] M1.8 Implement a bounded virtualized table view for the same rows and link table/chart inspection and selection through normalized row identities without mutating source data.
  - Evidence: `tables/bounded_table_view.gd` wraps Godot `Tree` and materializes at most the configured row window; `interactions/linked_selection.gd` projects normalized row selection into the table and scatter renderer. Headless tests cover missing-value inspection, table-to-chart and chart-to-table selection, additive selection, refresh preservation, bounded lifecycle, and source-table immutability.
- [x] M1.9 Apply a compatible full replacement revision while preserving eligible frame, selection, picking, and table state; diagnose and reset only the state whose identity is no longer valid.
  - Evidence: `session/plot_session.gd` consumes validated replay events and coordinates retained-model, renderer, table-window, and linked-selection updates. Headless tests prove revision 2 preserves frame transform, render node/resource, primitive IDs, bounded table offset/limit, and selected rows; declared identity-breaking revision 3 preserves the frame/table/resources while removing only invalid selections and pick primitives with an `identity-reset` diagnostic.
- [x] M1.10 Add public diagnostics for source/adapter/schema/revision/provenance, replay status, approximations, rejected fields, render lifecycle, and row-selection linkage.
  - Evidence: `diagnostics/plot_diagnostics.gd` emits a deterministic read-only snapshot covering active schema/message/plot/figure/revision, producer library and adapter, provenance, protocol limits, replay status/counters, source notices, combined diagnostics, approximation and rejected-path classification, renderer resource identities/counts, bounded table context, and linked renderer/table row selections.
- [x] M1.11 Prove deterministic replay, numerical/semantic assertions, public API usage, headless lifecycle, selection linkage, replacement behavior, resource stability, clean packaging, and desktop performance in CI.
  - Evidence: the allowlisted preview artifact rejects C#/.NET/native/demo dependencies and loads as a standard-Godot editor plugin. GitHub Actions run `M1 Pure GDScript (Godot 4.6.3)` with pinned fixture dependencies and official Godot checksum; remote run `29549390094` passed fixture regeneration, schemas, clean packaging, numerical/model/replay/render/table/session/diagnostics behavior, resource stability, and measured update budgets.
- [ ] M1.12 Publish the minimal quickstart and reference scene from released public APIs, record measured results and remaining risks, and require an explicit M1 review before live transport, Jupyter authentication, additional chart types, or WebXR implementation begins.
  - Started: `examples/m1/`, `scripts/prepare-m1-example.sh`, and `m1-review.md` provide the self-contained public reference scene, five-minute preparation path, measurements, deferred risks, and review boundary. Official-Godot remote CI confirmation and product-owner acceptance remain open.

### M1 Exit Criteria

- A clean standard-Godot project installs and runs the typed-GDScript addon without .NET, native binaries, network access, or demo-private APIs.
- The checked-in recorded session deterministically produces the expected scatter plot and bounded table from normalized schemas.
- Chart and table resolve the same stable rows for inspection and single/multi selection, including declared missing-value behavior.
- A compatible replacement revision updates incrementally and preserves eligible analytical state without scene-tree or rendering-resource growth.
- Invalid, oversized, out-of-order, duplicate, and identity-breaking fixtures produce structured diagnostics and preserve the last-good state.
- CI passes schema, numerical, semantic, serialization, lifecycle, selection, revision, packaging, and measured desktop-budget checks.
- The quickstart and reference scene use only public contracts, and the M1 review records dependency decisions, measured budgets, deferred capabilities, and authorization to proceed.

## 2. Test and Package Foundations

- [ ] 2.1 Create the clean module boundaries for pure plot core, Godot renderer/editor adapter, input adapters, and optional integrations.
- [ ] 2.2 Build clean standard-Godot install tests that reject C# sources, NuGet/package requirements, mandatory native binaries, and demo-only dependencies in the release artifact.
- [ ] 2.3 Add numerical contract, public-example, headless Godot lifecycle, visual regression, serialization migration, and resource-leak test harnesses.
- [ ] 2.4 Add a device-independent interaction replay harness with desktop and mocked XR adapter conformance suites.
- [ ] 2.5 Add versioned desktop and stereo-XR benchmark scenes that report frame time, update latency, allocations/memory, and visible degradation.
- [ ] 2.6 Create ecosystem-appropriate dependency manifests/locks, a machine-readable dependency inventory, required license/notice artifacts, and a README table declaring purpose, source, version policy, license, scope, installation, platform/export constraints, and fallback for every direct dependency.
- [ ] 2.7 Add release checks for undocumented runtime requirements, unexpected network fetches, license review, vulnerability disposition, integrity/source policy, unused packages, and dependency compatibility across the clean Godot/WebXR matrix.
- [ ] 2.8 Require each implementation task to link its reuse evaluation and keep project-owned adapters contract-focused; document owners, update plans, and exit strategies for any fork or vendored modification.

## 3. Plot Model and Data

- [ ] 3.1 Implement the versioned figure, view/axes, layer, mapping, coordinate, guide, theme, and interaction-state model with path-aware validation.
- [ ] 3.2 Implement normalized serialization, round-trip tests, schema versioning, and migration fixtures.
- [ ] 3.3 Implement row- and column-oriented typed table adapters with stable row identity and missing/non-finite value semantics.
- [ ] 3.4 Implement deterministic filter, sort, bin, aggregate, and derived-field transforms with provenance tests.
- [ ] 3.5 Implement append, replace, window, batch, cadence, and backpressure streaming policies with observable queue/drop metrics.
- [ ] 3.6 Implement equivalent pyplot-like and grammar-style typed-GDScript facades, prove normalized-spec parity, and add a C# consumer interop example without addon C# compilation.

## 3E. Analytical Client Foundations

- [ ] 3E.1 Define and fixture the virtualized analytical-table contract, complex dataframe semantics, bounded navigation, profiling, pivot/group operations, linked selections, and permission-separated copy/export.
- [ ] 3E.2 Define and fixture the session protocol handshake, capability/schema negotiation, ordering/idempotency, resynchronization, liveness/resume, correlated commands/cancellation, flow control, limits, and redacted tracing across replay and the first bus bridge.
- [ ] 3E.3 Define session-wide parameter resources, dependency evaluation, sensitive-value policy, bindings, transactional history, immutable analytical checkpoints, comparisons, and authorized deep-link serialization.
- [ ] 3E.4 Define declarative execution plans, placement policy, estimates/quotas, pushdown, progressive/approximate revisions, cancellation/supersession, cache identity/invalidation, and remote-render capability contracts.
- [ ] 3E.5 Build one vertical slice from a large mock DataFrame through remote filter/aggregate, virtualized table, session parameter, linked chart, checkpoint, protocol replay, and cancellation tests before expanding chart coverage.

## 5C. Publication and Platform Services

- [ ] 5C.1 Define artifact schemas and permission boundaries for editable bundles, immutable snapshots, deep links, images/documents, data, spatial geometry, notebook embeddings, tours/recordings, and support bundles.
- [ ] 5C.2 Implement publication redaction previews, expiration/revocation metadata, deterministic provenance manifests, format fidelity diagnostics, and representative PNG/SVG/PDF/CSV/Arrow/GLB fixtures as supported.
- [ ] 5C.3 Define versioned registries and conformance fixtures for marks, adapters, transports, auth providers, transforms, inspectors, interaction tools, commands, exporters, and asset/theme packs.
- [ ] 5C.4 Implement the unified typed command registry, command palette/help metadata, global permission-filtered search, recent/favorites, and context-preserving navigation.
- [ ] 5C.5 Implement production diagnostics for normalized specs, adapters, protocol, execution, streams, renderer/picking, dependencies, and redacted bounded capture/support bundles.

## 5D. Collaboration, Governance, and Annotations

- [ ] 5D.1 Reserve actor, scope, ownership, permission, annotation, audit, and conflict metadata in foundational schemas while keeping providers optional for single-user use.
- [ ] 5D.2 Define optional presence, private/shared selection, manipulation lease, presenter/follow, shared-anchor, late-join, reconnect, conflict, and per-user/shared history contracts.
- [ ] 5D.3 Implement analytical annotations for data/mark/region/axis/view/frame/checkpoint/provenance targets with author, time, scope, permissions, revision, orphan/rebind, and ordered tour references.
- [ ] 5D.4 Define host-provided user/group/project/tenant and resource/data/row/field/command/export/share policies with constraint propagation through derivation, cache, snapshot, and export.
- [ ] 5D.5 Define audit, retention, legal-hold, revocation, ownership-transfer, and deletion events and prove that visual/session operations do not implicitly delete or widen access to remote analytical resources.

## 4C. Geospatial Analytical Visualization

- [ ] 4C.1 Run dependency scorecards and proof-of-concept tests for deck.gl's semantic model; 3D Tiles for Godot/Cesium Native; Geodot/GDAL; `godot-gis` and its Rust/PROJ/format/index/renderer features; MapTileProvider or a maintained lightweight equivalent; appropriate maintained Godot terrain packages; BlenderGIS as an external authoring tool; MapLibre-compatible sources; PROJ; GeoArrow/GeoParquet; GeoPandas; and candidate spatial query engines across standard Godot, native XR, WebXR, license, security, size, and performance constraints.
- [ ] 4C.1a Publish a Godot geospatial candidate matrix covering purpose, Godot versions, maintenance, license, GDScript/GDExtension/module model, transitive binaries, platforms, web/WebXR, provider/auth coupling, coordinates/precision, metadata/picking, cache/offline behavior, performance, public API, and thin-adapter feasibility; record adopt/wrap/optional/reject decisions without treating survey inclusion as endorsement.
- [ ] 4C.2 Define versioned geospatial descriptors for CRS, axis/unit/datum/vertical/epoch/accuracy, geometry/raster/tile/terrain sources, feature identity, bounds, time, style, LOD, attribution, permission, and transformation provenance.
- [ ] 4C.3 Extend the retained model with the minimal deck.gl-inspired baseline of point/text, path, polygon, raster/image, aggregate grid/density, explicit coordinates, planar/local views, picking, inspection, and linkage without importing JavaScript types into public contracts; make arcs/trips, tiles, terrain, point clouds, 3D Tiles, globe, and other advanced types adapter-advertised optional capabilities.
- [ ] 4C.4 Implement companion adapters using approved PROJ/GDAL/GeoArrow tooling for authoritative transforms, format inspection, bounded interchange, validity, generalization, tiling, and diagnostics; do not recreate those facilities in GDScript.
- [ ] 4C.5 Implement Godot local-origin/tangent-frame or camera-relative precision, rebasing, projection/view controls, north/up/scale/coordinate guides, picking, feature inspection, and LOD-preserving identity.
- [ ] 4C.6 Integrate or wrap the approved optional Godot 3D Tiles/terrain package and implement explicit standard-Godot/WebXR fallbacks, capability diagnostics, authentication, caching, and attribution.
- [ ] 4C.7 Implement declarative spatial selections, measurements, and approved backend operations with planar/geodesic semantics, units, accuracy, execution plans, provenance, and linked table/chart views.
- [ ] 4C.7a Verify core implements no general GIS parser, CRS database, tile generator, geocoder, router, topology editor, spatial database, photogrammetry pipeline, or advanced geoprocessing engine and that missing optional capabilities fail transparently.
- [ ] 4C.8 Implement temporal geospatial playback, trajectories, trails, streaming positions, shared time parameters, snapshots, and linked non-geospatial views.
- [ ] 4C.9 Add attribution/licensing/privacy/export policy enforcement and uncertainty/generalization/staleness presentation for every external geographic source.
- [ ] 4C.10 Add conformance and performance fixtures for CRS/axis order, dateline/poles, vertical references, precision/rebasing, invalid/complex geometry, tiles/terrain, GeoArrow, spatial queries, trajectories, offline/missing content, attribution, desktop, native XR, and WebXR.
- [ ] 4C.11 Prototype the same bounded vector/CRS/picking fixture through Geodot and `godot-gis`, compare adapter size, correctness, license/distribution, binary platforms, WebXR, performance, and maintenance, and select neither, one, or complementary optional roles from evidence.
- [ ] 4C.12 Publish a BlenderGIS-to-Godot authoring template and validator for bounded terrain/scene GLB plus sidecar CRS, local origin, axes, scale, vertical reference, bounds, accuracy, source revision, attribution/license, provider terms, and generation settings, with credentials excluded.

## 3A. Python Plot Interchange

- [ ] 3A.1 Publish JSON Schema and canonical fixtures for the transport-independent `plot-message` envelope, normalized spec, diagnostics, provenance, full replacement, and patch updates.
- [ ] 3A.2 Build the companion Python adapter package with registry, compatibility report, resource limits, deterministic IDs, and no-pickle/no-code security tests.
- [ ] 3A.3 Implement Matplotlib extraction for figures, subplots, lines, scatter collections, bars, histograms, images, surfaces, axes/scales, titles, annotations, legends, colors, and stable source identities.
- [ ] 3A.4 Implement Seaborn adaptation through its compiled Matplotlib output and preserve source-library/statistical provenance where exposed.
- [ ] 3A.5 Implement Plotly adaptation from validated figure JSON for supported traces, subplots, layout, 3D scenes, frames, and selection identity.
- [ ] 3A.6 Implement Altair/Vega-Lite adaptation from versioned JSON specs with inline/named data, supported transforms, layers, facets, concatenation, encodings, scales, guides, and parameters.
- [ ] 3A.7 Implement Bokeh adaptation from standalone/document JSON for supported glyphs, column data sources, ranges, axes, layouts, and selections without executing callbacks.
- [ ] 3A.8 Implement the pure-GDScript envelope validator/normalizer and full/patch receiver with idempotency, ordering, size limits, unknown-field handling, and structured rejection events.
- [ ] 3A.9 Implement one optional message-bus bridge as a separate integration and prove that recorded envelopes replay identically through in-process and bus transports.
- [ ] 3A.10 Add cross-library golden fixtures and semantic/visual conformance reports covering supported, approximated, fallback, and rejected features.

## 3B. Session Data and Locally Authored Plots

- [ ] 3B.1 Define the transport-neutral session data descriptor, opaque handle, schema, semantic type, index/coordinate, unit, preview, capability, permission, freshness, revision, and provenance contracts.
- [ ] 3B.2 Implement Python adapters for pandas DataFrame/Series, NumPy arrays, Arrow-compatible tables, xarray objects, and supported dataframe-interchange objects with bounded inspection and no pickle/arbitrary-code paths.
- [ ] 3B.3 Implement the pure-GDScript session data catalog with discovery, search, type/shape filters, preview, statistics, freshness, permission, source-kernel, and disconnected/expired status.
- [ ] 3B.4 Implement bounded data requests for selected columns, row/page ranges, filters, aggregates, samples, and snapshots with cancellation, limits, backpressure, and revision checks.
- [ ] 3B.5 Implement the local plot builder for choosing fields, transforms, encodings, marks, scales, guides, interactions, and frame/compound placement from a data descriptor.
- [ ] 3B.6 Implement deterministic compatible-chart and encoding recommendations from semantic types, cardinality, shape, units, and missingness with explanations and user confirmation.
- [ ] 3B.7 Implement `live_reference`, `snapshot`, and `derived` bindings with stale-handle, kernel-restart, schema-change, revision-conflict, and reconnect behavior.
- [ ] 3B.8 Implement safe declarative filter, sort, derive, bin, aggregate, group, sample, reshape, and join capability negotiation with full provenance; execute locally or remotely according to declared policy.
- [ ] 3B.9 Implement “selection to dataset” and “view data” workflows that register chart selections or displayed/derived tables as session data objects without silently mutating their inputs.
- [ ] 3B.10 Add pandas-focused fixtures for indexes, MultiIndex, categorical, nullable, timezone-aware, decimal, object, extension, duplicate-column, large, empty, and changing DataFrames.
- [ ] 3B.11 Open a follow-up OpenSpec change for general in-session data generation/editing and external acquisition, including manual tables, formulas, simulations, procedural producers, joins, file/browser pickers, Excel/CSV/Parquet imports, uploads/staging, databases/object stores, and authorized writeback, using this capability's descriptor and provenance contracts.

## 3C. Notebook Session Workbench

- [ ] 3C.1 Define transport-neutral descriptors for Jupyter server/workspace, kernel/session, notebook/document, cell/execution, output, variable/data object, environment, capability, status, and provenance relationships.
- [ ] 3C.2 Implement a companion-side Jupyter adapter for authenticated discovery and status, with explicit capability negotiation and no credentials stored in plot specifications.
- [ ] 3C.2a Implement Godot host connection profiles and authentication UX for authorized local, remote, and private-network Jupyter deployments, using pluggable token, broker, browser/SSO, device-flow, certificate, or proxy providers as platform capabilities permit, with protected or ephemeral secret handling.
- [ ] 3C.2b Implement hierarchical server/workspace-or-project/notebook/kernel discovery and a disambiguating target chooser with recent targets, availability, authentication state, permissions, and explicit selection.
- [ ] 3C.3 Implement a pure-GDScript spatial catalog that navigates notebooks, cells, outputs, variables, plots, data objects, frames, and derived views bidirectionally through provenance.
- [ ] 3C.4 Implement busy/idle/restarting/dead, execution-count, stale-output, error, environment-version, reconnect, and kernel-restart presentation and recovery behavior.
- [ ] 3C.5 Implement capability-gated action requests for refresh, rerun-known-cell, interrupt, restart, declared-parameter update, and pre-registered commands with preview, confirmation, timeout, cancellation, output, and audit provenance.
- [ ] 3C.6 Add security and conformance tests proving the core addon cannot submit arbitrary code, expose credentials, confuse notebook/kernel identities, or present stale outputs as current.
- [ ] 3C.7 Build an immersive workbench reference flow from notebook cell to DataFrame to plot to compound figure and back to provenance, using desktop, native XR, and WebXR inputs.
- [ ] 3C.8 Verify the Jupyter implementation uses backend-neutral session/document/execution/output/object/command contracts and isolates Jupyter-only fields in namespaced adapter metadata.
- [ ] 3C.9 Implement persistent desktop and immersive active-context indicators plus safe, cancellable context switching with affected-binding preview, retain/snapshot/rebind policies, and no same-name implicit rebinding.
- [ ] 3C.10 Add conformance fixtures for multiple servers, duplicate notebook names, unavailable private routes, expired authorization, unsupported WebXR auth methods, mixed-context frames, restore while offline, and explicit reconnect/target replacement.

## 3D. Future Computational Backends

- [ ] 3D.1 Publish the backend adapter interface, capability vocabulary, namespaced-extension rules, lifecycle, authentication boundary, status model, provenance mapping, command mapping, and conformance fixture format.
- [ ] 3D.2 Build a mock non-Jupyter adapter proving plots, data objects, streams, files, provenance, and read-only commands do not depend on notebook/kernel/cell terminology.
- [ ] 3D.3 Open a follow-up OpenSpec change after the Jupyter vertical slice to evaluate candidate Python, R, Julia, database, workflow, and hosted analytical backends against user demand, interchange, provenance, security, deployment, and WebXR connectivity.

## 4. Scientific Layout and Rendering

- [ ] 4.0 Port retained Godot rendering behavior into typed GDScript against new contracts; do not translate legacy classes one-for-one.
- [ ] 4.1 Implement continuous, categorical, temporal, logarithmic, and 3D spatial scales with domain/range/inversion tests.
- [ ] 4.2 Implement deterministic ticks, locale-aware formatting, axes, grids, labels, legends, layout collision policy, and accessible themes.
- [ ] 4.3 Implement the renderer diff/lifecycle layer with stable render-object and picking identities.
- [ ] 4.4 Deliver a vertical scatter-plot slice with guides, missing values, editor preview, runtime rendering, streaming updates, and source-row picking.
- [ ] 4.5 Add MVP line, bar, histogram, surface, and approved spatial marks using shared scale, guide, batching, and level-of-detail infrastructure.
- [ ] 4.6 Establish editor/runtime visual baselines and validate no scene-tree or rendering-resource growth across repeated updates.

## 4A. Quantum Circuit Visualization

- [ ] 4A.1 Inventory the existing circuit JSON, loader, renderer, fixtures, and demos; record field-level preservation gaps against supported Qiskit `QuantumCircuit` and `CircuitInstruction` versions.
- [ ] 4A.2 Define JSON Schema and fixtures for the normalized circuit payload, including registers, bits, instructions, parameters, modifiers, measurements, conditions/control flow, directives, phase, timing/layout metadata, dependencies, layers, and diagnostics.
- [ ] 4A.3 Implement a Qiskit Python adapter using ordered circuit data and `circuit_to_dag`, with stable identities, supported-version fixtures, unknown-instruction handling, and optional QPY/OpenQASM provenance.
- [ ] 4A.4 Port retained loading, validation, deterministic topological layering, and circuit resources to pure typed GDScript without QuikGraph or `System.Text.Json`.
- [ ] 4A.5 Implement batched wire, classical-wire, gate, control, target, measurement, condition, barrier, grouping, and label marks with picking and source-instruction identity.
- [ ] 4A.6 Implement conventional, dependency-expanded, hardware-layout, timing, and before/after transpilation views only where supplied semantics support them.
- [ ] 4A.7 Implement layer/time scrubbing, gate and wire inspection, expand/collapse, filtering, parameter handles, dependency highlighting, comparison linking, undo, and reset through normalized analytical controls.
- [ ] 4A.8 Add embodied/WebXR circuit exploration tests for standing along the execution axis, interior readability, navigation, selection, scrubbing, parameter manipulation, and performance on large circuits.
- [ ] 4A.9 Add Qiskit-version conformance fixtures for standard gates, custom gates, symbolic parameters, measurement, classical conditions/control flow, barriers, layouts, transpiled circuits, and unsupported features.

## 4B. Spatial Visual Design and Assets

- [ ] 4B.1 Produce a documented visual benchmark of Plotly, Observable Plot, and Apache ECharts covering hierarchy, palettes, guides, typography, interaction states, 3D navigation, details on demand, dark mode, and accessibility without copying branded elements.
- [ ] 4B.2 Define the quiet-scientific-instrument principles and semantic token schema for color, typography, dimensions, depth, materials, lighting, states, motion, target size, viewing distance, density, and effect budgets.
- [ ] 4B.3 Design and validate original light, dark, high-contrast, color-vision-safe, presentation, and WebXR-performance themes against representative chart and circuit fixtures.
- [ ] 4B.4 Build reusable Godot assets for axes, ticks, grids, frames, points, bars, lines/tubes, surfaces, arrows, uncertainty marks, legends, annotations, and orientation landmarks with declared pivots, dimensions, batching, and LOD.
- [ ] 4B.5 Build reusable interactive assets for hover/focus, handles, slider tracks/thumbs, dials, grab anchors, buttons, slice planes, thresholds, selection volumes, tooltips, and reset controls across ray and direct-touch modes.
- [ ] 4B.6 Build a circuit asset family for standard/opaque gates, controls, targets, swaps, measurements, conditions, barriers, wire types, dependency highlights, parameter handles, and comparison states.
- [ ] 4B.7 Create a visual-system gallery showing every asset, token, theme, state, viewing-distance class, density level, interior/exterior condition, and WebXR fallback from public APIs.
- [ ] 4B.8 Add perceptual/visual regression, contrast, redundant-encoding, label legibility, occlusion, motion-comfort, material/mesh count, draw-call, memory, and stereo frame-budget gates.
- [ ] 4B.9 Define the versioned asset-pack manifest, semantic role registry, sockets/material parameters, inheritance/fallback chain, validation diagnostics, and compatibility migration policy.
- [ ] 4B.10 Implement import and preview workflows for GLB/glTF, Godot meshes/resources/scenes, and sandboxed typed-GDScript procedural asset providers.
- [ ] 4B.11 Implement theme-pack registration, composition, hot switching, partial-pack fallback, performance-tier selection, license/provenance display, and clean removal.
- [ ] 4B.12 Publish Blender and Godot authoring templates with correct scale, pivot, axes, label/interaction anchors, material slots, collision proxies, LOD naming, export settings, and validation examples.

## 5. Desktop and Immersive Interaction

- [ ] 5.1 Implement deterministic point, inspect, select, multi-select, brush, filter, navigate, manipulate, and reset state transitions.
- [ ] 5.2 Implement mouse, keyboard, and touch adapters with focus, readable inspection, and non-color-only feedback.
- [ ] 5.3 Implement optional controller-ray and direct-hand XR adapters that emit the same intents without a core XR dependency.
- [ ] 5.4 Implement linked selection/filtering across views with transformation provenance and event payload tests.
- [ ] 5.5 Validate target size, viewing-distance typography, depth/occlusion behavior, seated/standing reach, and stereo performance on the declared XR matrix.
- [ ] 5.6 Implement typed analytical parameters and bindings for handles, sliders, dials, buttons, scroll/joystick input, and one/two-hand manipulation with preview, commit, cancel, undo, and reset behavior.
- [ ] 5.7 Implement embodied spatial-view transforms, plot bounds, entry/reset landmarks, interior axes/guides, and distinct locomotion, orbit/pan, scale-domain zoom, and whole-plot manipulation state.
- [ ] 5.8 Implement interactive slice planes, thresholds, axis-domain handles, and 3D selection volumes with linked-view provenance.
- [ ] 5.9 Implement the WebXR capability adapter with ray/select baseline, controller and squeeze enhancement, progressive hand input, capability-loss recovery, and no XR Tools dependency.
- [ ] 5.10 Add WebXR browser/headset smoke scenes and benchmarks for entering plots, interior inspection, controls, scale zoom, slicing, reset, adaptive detail, and interaction fallback.

## 5A. Chart Frame Session Interaction

- [ ] 5A.1 Inventory current frame creation/deletion, chart/size/style selection, placement/movement, topic routing, mapping locks, binding modes, status, and workspace persistence; record reusable behavior and coupling gaps.
- [ ] 5A.2 Implement versioned pure-GDScript resources for frame, binding, layout relationship, session, command/history, and restore state with migrations and stable identities.
- [ ] 5A.3 Implement transport-neutral source/stream catalog discovery, search, preview, compatibility scoring, subscription status, freshness, schema-change, reconnect, and last-good-revision behavior.
- [ ] 5A.4 Implement `follow_source`, `suggest_source`, `user_locked`, and `derived` representation policies with compatible-view previews, local overrides, reset-to-source, and provenance.
- [ ] 5A.5 Implement single/multi selection and explicit content/frame/layout input modes with visible capture, permission/lock state, keyboard/controller modifiers, cancel, and focus restoration.
- [ ] 5A.6 Implement frame create, place, move, rotate, resize, aspect policy, dock, snap, duplicate, snapshot, rebind, restyle, lock, hide/show, minimize/focus, reset, and delete commands with preview and undo/redo.
- [ ] 5A.7 Implement multi-frame align, distribute, stack, tile, group/ungroup, compare, synchronize, link selection/camera/domain, isolate, and teleport/focus operations.
- [ ] 5A.8 Implement frame chrome and assets for title/source/status, selection bounds, transform/resize handles, docking/snap guides, stream state, provenance, permissions, and stale/error conditions using semantic asset roles.
- [ ] 5A.9 Implement desktop, native XR, and WebXR conformance tests that disambiguate frame manipulation from chart zoom/brush/handles and validate direct grab, ray, mouse, keyboard, touch, and fallback workflows.
- [ ] 5A.10 Implement session save/restore, autosave, crash-safe writes, import/export, schema migration, missing-source/theme fallback, reconnect, and deterministic undo/redo boundaries.
- [ ] 5A.11 Add frame-count, update-rate, visibility suspension, LOD, layout, persistence, and WebXR stereo benchmarks for representative analytical sessions.

## 5B. Compound Figures and Quad Plots

- [ ] 5B.1 Define the versioned figure composition tree for row, column, grid, named mosaic, spanning cell, inset, overlay, tab/page, and explicit spatial layout nodes with stable view and slot identities.
- [ ] 5B.2 Implement layout constraints for weight, minimum/ideal size, aspect, gap, padding, alignment, guide regions, overflow, and responsive breakpoints with deterministic resolution tests.
- [ ] 5B.3 Normalize source-published Matplotlib subplots, Plotly subplots, Vega-Lite composition, Bokeh layouts, and native compound specifications into the composition tree with compatibility diagnostics.
- [ ] 5B.4 Implement session workflows to create a compound frame, choose a preset such as 2×2 quad, insert/move/replace/duplicate/remove views, span/reorder slots, and split a view back into its own frame with undo/redo.
- [ ] 5B.5 Implement independent per-view static/live/derived/snapshot bindings, statuses, policies, revisions, provenance, pause/reconnect, and failure isolation inside one figure.
- [ ] 5B.6 Implement compatible shared axes/scales, guide deduplication, shared legends/colorbars, linked cursor/selection/filter/domain/time/parameter state, and explicit unlink behavior.
- [ ] 5B.7 Implement compound selection hierarchy and input routing for frame, composition, view, and content scopes across desktop, native XR, and WebXR.
- [ ] 5B.8 Implement flat, curved, paged, focus-plus-context, and explicit spatial presentation policies with readable transitions and deterministic reset to authored layout.
- [ ] 5B.9 Implement compound figure persistence, import/export, source-versus-local provenance, snapshot behavior, missing-view placeholders, and layout-schema migration.
- [ ] 5B.10 Add visual, interaction, update-isolation, layout, accessibility, and WebXR performance fixtures for 1×2, 2×2, asymmetric mosaic, inset, mixed-source, and partially disconnected figures.

## 6. Migration and Release

- [ ] 6.1 Replace the current data room as the reference architecture with a small gallery and interaction lab built only from public APIs.
- [ ] 6.2 Publish the preview API, compatibility decision, old-to-new mapping guide, serialized-spec policy, and explicit removals.
- [ ] 6.3 Decide from known consumer evidence whether to implement a bounded legacy adapter; otherwise publish the clean-break migration release.
- [ ] 6.4 Preserve circuit visualization through the new quantum capability while quarantining or removing desktop-capture, workspace-orchestration, generic-widget, duplicate-addon, and stale-documentation surfaces not accepted by the audit.
- [ ] 6.5 Replace or remove QuikGraph, MSAGL, MathNet, `System.Text.Json`, and other .NET-only code paths; verify the core addon contains no `.cs`, `.csproj`, or binary dependency.
- [ ] 6.6 Run every numerical, visual, interaction, packaging, compatibility, memory, desktop, and stereo-XR release gate and publish measured tier results.
- [ ] 6.7 Cut the first preview release, collect workflow telemetry/feedback without collecting user data by default, and reprioritize the next OpenSpec changes.

## 6A. Guided Demo and User Testing

- [ ] 6A.1 Define the demo package boundaries for minimal backend, recorded fixtures, standard-Godot project, example notebooks, study materials, and five-minute quickstart using only public contracts.
- [ ] 6A.2 Evaluate and select maintained packages for the minimal backend, message transport, fixture playback, tutorial presentation, and opt-in study events under the dependency-first scorecard.
- [ ] 6A.3 Implement deterministic replay with stable identities, controllable time, pause/step/restart, replacement and patch messages, stream updates, permission changes, status transitions, disconnect, schema change, and reconnect injection.
- [ ] 6A.4 Implement the bounded demo backend with two workspaces, duplicate notebook filenames, kernel-like sessions, published plots, DataFrame-like objects, read-only and authorized modes, and no arbitrary-code endpoint or private schema.
- [ ] 6A.5 Add optional live Jupyter examples producing supported Matplotlib, pandas, Plotly, compound-figure, spatial, and Qiskit objects through the same Godot-facing contracts.
- [ ] 6A.6 Build the restrained public Godot analytical-studio scene with connection/context, catalog, chart workspace, provenance/data inspection, help, and diagnostics surfaces using desktop-first public APIs.
- [ ] 6A.7 Author the restartable curriculum for context selection, published-plot provenance, plotting data, chart/frame manipulation, linked compound views, embodied navigation, streams/snapshots/recovery, and safe mixed-context notebook switching.
- [ ] 6A.8 Add layered help, input hints, unavailable-capability explanations, glossary, searchable help/commands, short demonstrations, textual alternatives, and dismissible onboarding.
- [ ] 6A.9 Define and implement opt-in privacy-preserving study-event schemas, consent, local/remote collection policy, retention, export, deletion, redaction, and no-collection behavior.
- [ ] 6A.10 Publish versioned first-impression, guided-workflow, and open-analysis study protocols with representative participant criteria, tasks, observation rubrics, comfort/accessibility checks, interviews, and success thresholds.
- [ ] 6A.11 Add automated clean-start, replay-determinism, tutorial-state, interaction-replay, accessibility-fallback, disconnect-recovery, context-safety, and desktop/WebXR performance acceptance tests using the public demo.
- [ ] 6A.12 Reuse the same fixture set for documentation and screenshots, record formative study findings against requirements, and block or revise workflows with severe comprehension, privacy, accessibility, or safety failures.
