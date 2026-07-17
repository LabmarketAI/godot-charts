## Why

The current repository demonstrates that charts and workspaces can exist in Godot 3D/XR, but it does not yet provide a coherent, tested plotting library for data scientists: its public API, language/runtime requirements, interaction model, documentation, and verification strategy disagree. We need an explicit foundation decision now so future work produces a matplotlib/R-like scientific plotting product instead of accumulating more demo-specific features.

The longer product direction is an immersive analytical workbench, initially with the feeling of a VR GUI for a Jupyter session: backend-produced plots, data objects, files, parameters, outputs, provenance, and session-created views become spatial objects that remain connected to their computational context. Jupyter is the first target, not the permanent architectural boundary.

## What Changes

- Audit the existing chart, data, widget, demo, and XR code against a data-scientist-first product rubric, then record a time-boxed keep/rewrite/remove decision for each subsystem.
- Adopt a dependency-first implementation policy: search maintained Godot addons and established upstream packages before writing infrastructure, prefer configuration and thin adapters over reimplementation, and record why custom code is necessary when no acceptable dependency satisfies the contract.
- **BREAKING** Replace the current chart-per-node and Chart.js-shaped public surface with a stable plotting model built around figures, axes/scales, layers/marks, tabular data mappings, themes, and reusable plot specifications.
- **BREAKING** Ship the core as a pure typed-GDScript Godot addon that runs in standard Godot without .NET, native binaries, or package restoration; provide C# consumption through Godot's normal script interop rather than a second implementation.
- Separate the portable plotting kernel from Godot rendering, editor integration, XR input adapters, and the showcase application so the library can be tested without a headset or demo scene.
- Add scientifically credible scales, ticks, labels, legends, missing/non-finite value behavior, categorical and continuous mappings, deterministic layouts, and accessible visual defaults.
- Add chart-native interaction semantics—hit testing, hover, selection, filtering, brushing, linked views, inspection, manipulation, and reset—with equivalent mouse, touch/keyboard, controller-ray, and direct-hand pathways where supported.
- Treat charts as embodied analytical spaces: users can stand within a coordinate volume, navigate without losing analytical context, and directly manipulate axes, scale domains, slices, filters, time, thresholds, and view orientation through world-space handles and controls.
- Make WebXR a first-class target with capability-negotiated ray, controller, hand, touch, and fallback inputs rather than treating browser XR as a desktop rendering variant.
- Establish an original, modern-but-relatable 3D visual system inspired by Plotly's scientific/3D familiarity, Observable Plot's restrained data-first grammar, and Apache ECharts' polished themes and interaction states, with production-ready assets for marks, guides, controls, inspection, selection, and quantum circuits.
- Make chart frames first-class session objects that users can discover, select, place, move, rotate, resize, dock, group, duplicate, compare, bind to streams, restyle, lock, hide, restore, and remove without conflating frame manipulation with interaction inside the chart.
- Allow one frame to contain a compound figure of multiple coordinated chart views—such as a 2×2 diagnostic/quad plot—whether published as one plot specification or composed locally from several plots or streams during a session.
- Allow users to discover tabular or array-like data objects exposed by a Jupyter/Python session—especially pandas DataFrames—inspect their schema and preview, choose compatible visual mappings, and create locally authored live or snapshot plots even when no plot was published with the data.
- Preserve notebook, kernel, cell, execution, variable, output, and environment provenance across plots and data objects and provide a capability-gated workbench surface for navigation, status, refresh, parameter changes, and authorized execution requests without embedding a Python runtime or cloning JupyterLab into the addon.
- Accept versioned plot messages produced from live Python plotting objects, with official adapters for Matplotlib/Seaborn, Plotly, Altair/Vega-Lite, and Bokeh that normalize supported semantics into the retained plot specification.
- Establish performance budgets and incremental/batched rendering paths suitable for large static and streaming datasets in desktop and stereo XR rendering.
- Replace helper-only CI coverage with contract, numerical, rendering, interaction, performance, packaging, and representative desktop/XR smoke tests.
- Preserve quantum-circuit visualization as a first-class specialized plot with Qiskit object interchange and the same retained-model, scientific-fidelity, interaction, WebXR, and embodied-analysis contracts as other charts; quarantine unrelated desktop capture, workspace orchestration, and general-purpose widget features.
- Replace the current data room as the onboarding reference with a focused public demo: a minimal contract-faithful backend, deterministic recorded message-bus replay, optional live Jupyter mode, a restrained Godot analytical studio, guided curriculum, privacy-preserving user-study instrumentation, and executable release acceptance flows.
- Preserve the old API only behind an explicitly scoped migration adapter if real consumer usage justifies its cost; otherwise document the clean break.

## Capabilities

### New Capabilities

- `plot-specification-api`: Figure/axes/layer composition, tabular data mappings, serialization, typed-GDScript API, C# interop, errors, and migration-facing public API behavior.
- `scientific-scales-and-guides`: Continuous, categorical, temporal, logarithmic, and spatial scales plus deterministic axes, ticks, labels, legends, coordinate systems, and missing-value rules.
- `godot-chart-rendering`: Rendering-backend contracts, chart scene integration, incremental updates, picking metadata, theming, editor previews, and resource lifecycle behavior.
- `immersive-chart-interaction`: Device-independent interaction intents and desktop/VR/XR behaviors for inspection, selection, brushing, filtering, linked views, navigation, and accessibility.
- `data-ingestion-and-streaming`: Typed/tabular inputs, adapters, validation, transformations, aggregation, streaming updates, backpressure, and reproducibility behavior.
- `python-plot-interchange`: Message envelope, Python object adapters, semantic compatibility levels, provenance, updates, transport independence, security limits, and fallback behavior for major Python plotting libraries.
- `quantum-circuit-visualization`: Qiskit circuit interchange, semantic circuit model, dependency/layer layout, faithful 2D/3D rendering, inspection, comparison, parameter controls, and embodied circuit exploration.
- `spatial-visual-design-system`: Visual principles, design tokens, themes, materials, typography, interaction states, reusable 3D asset kit, accessibility, WebXR budgets, and visual-regression governance.
- `chart-frame-session-interaction`: Frame lifecycle, selection and manipulation modes, stream/plot binding and representation policy, spatial layout, grouping/linking, session history and persistence, status, permissions, and desktop/XR/WebXR input parity.
- `compound-figure-composition`: Multi-view figures within one frame, source and session composition, grids/mosaics/insets/spatial layouts, per-view bindings, shared guides/scales, linked interactions, responsive layout, persistence, and compound export/provenance.
- `session-data-and-derived-plots`: Session data catalog, pandas/tabular object handles, schema and preview, bounded transfer, visual mapping recommendations, local plot creation, revisions/snapshots, transformations, provenance, persistence, and the extension boundary for future in-session data generation.
- `notebook-session-workbench`: Jupyter connection and capability model, notebook/kernel/cell provenance, spatial catalog/navigation, output and variable relationships, authorized actions, execution safety, reconnect/restart behavior, and the boundary between the plotting addon and companion notebook integrations.
- `computational-backend-adapters`: Backend-neutral analytical-session contracts, adapter discovery/capabilities, normalized provenance and commands, Jupyter as the initial adapter, and compatibility gates for future Python, R, Julia, database, workflow, or hosted analytical backends.
- `quality-performance-and-distribution`: Compatibility matrix, packaging, test layers, visual baselines, performance budgets, examples, documentation, and release gates.
- `quality-performance-and-distribution` also governs the dependency inventory, adoption criteria, manifests, license/security provenance, optional-feature boundaries, and README disclosure required to keep installation reproducible and architectural ownership explicit.
- `guided-demo-and-user-testing`: Minimal backend, deterministic plot-message replay, optional live Jupyter path, onboarding scene, representative analytical fixtures, guided curriculum, help scaffolding, privacy-preserving research instrumentation, study protocols, and demo-based release evidence.
- `analytical-table-inspection`: Virtualized table views, complex dataframe semantics, bounded navigation, grouping/pivoting, linked chart selection, profiling, and permission-aware export.
- `message-transport-and-session-protocol`: Transport-neutral handshake, negotiation, ordering, resynchronization, liveness, commands, cancellation, flow control, schema evolution, and redacted protocol diagnostics.
- `session-parameters-and-reproducible-views`: Session-wide typed parameters, dependent values, immutable analytical checkpoints, bookmarks/deep links, comparisons, and transactional history.
- `query-planning-and-progressive-execution`: Declarative execution placement, estimates/quotas, pushdown, progressive and approximate results, cancellation, caching, and remote-render boundaries.
- `sharing-export-and-publication`: Editable bundles, snapshots, links, images/documents, data, spatial geometry, embeddings, recordings, redaction, permissions, expiration, and publication provenance.
- `extension-command-and-diagnostics-platform`: Versioned extension registries, dependency isolation, unified commands, global discovery, production diagnostics, and redacted support capture.
- `collaboration-governance-and-annotations`: Collaboration-compatible state, presence/manipulation, reconciliation, analytical annotations/stories, resource/data governance, audit, retention, and deletion.
- `geospatial-analytical-visualization`: Dependency-first GIS integration, CRS/datum/epoch semantics, deck.gl-inspired layers and views, map/globe/local/embodied presentation, Earth-scale precision, tiles/terrain, GeoArrow interchange, spatial analysis, time, measurement, attribution, privacy, and geospatial conformance.

### Modified Capabilities

None. This repository has no existing OpenSpec capability specifications; the current behavior will be captured as migration evidence rather than treated as the desired contract.

## Impact

- Primary impact: `addons/godot-charts/`, which is expected to be substantially rewritten and reorganized.
- Supporting impact: `tests/`, `.github/workflows/ci.yml`, installation/sync scripts, public README/API examples, and a smaller purpose-built demo/gallery.
- The `demo/` data-room application becomes a consumer and XR integration testbed rather than the architectural owner of interactions, data routing, or workspace state.
- The Godot version floor, rendering primitives, dataframe interchange formats, and optional XR dependencies remain decision gates; the core runtime decision is standard Godot plus typed GDScript.
- Every direct runtime, editor, build, test, companion-service, Python, and optional integration dependency will be declared in machine-readable manifests and summarized in the README with purpose, version policy, license, installation source, platform/export constraints, and whether it is bundled, required, optional, or development-only.
- C# chart classes and two-line GDScript wrappers will be retired. QuikGraph, MSAGL, MathNet, and `System.Text.Json` usages must be replaced with GDScript/Godot implementations, scoped into optional integrations, or removed.
- Existing scenes and consumers should expect breaking node names, data shapes, exported properties, signals, installation steps, and serialized resources unless a migration adapter is approved.
