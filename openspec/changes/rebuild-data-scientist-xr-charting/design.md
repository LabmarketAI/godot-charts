## Context

The repository is a useful prototype but not a dependable library baseline. The distributable addon contains substantial C# implementations exposed through two-line GDScript wrappers, while installation and examples present it as a GDScript addon. The README, `CLAUDE.md`, project SDK versions, and CI describe different toolchains. Rendering is largely destructive scene-tree regeneration; interaction lives mostly in demo/widget code rather than chart semantics; and tests compile selected pure C# helpers with Godot stubs but do not exercise the chart classes, plugin loading, rendering, packaging, or XR input.

The product stakeholder is a data scientist who expects concise plotting, statistically honest defaults, reproducible specifications, dataframe-friendly inputs, high-quality guides, and interactive inspection without becoming a Godot scene expert. Godot developers, addon packagers, and XR users are secondary stakeholders. Headsets and optional XR toolkits cannot be required for core development or tests.

## Goals / Non-Goals

**Goals:**

- Establish one canonical plotting model and documented language/runtime support.
- Make 2D-in-3D and genuinely spatial plots scientifically credible and composable.
- Make interaction device-independent at the chart model boundary and immersive at adapters.
- Bound performance and correctness with automated release gates.
- Decide reuse from evidence before migrating implementation code.

**Non-Goals:**

- Rebuilding the data-room application, a general XR desktop, or a full UI toolkit as library core.
- Reimplementing pandas, Arrow, NumPy, R, or a statistical formula engine inside Godot.
- Guaranteeing every chart type, dataframe format, or XR device in the first release.
- Preserving the current public API when preservation conflicts with the new model.

## Decisions

### Use a strangler rebuild with an audit gate

New work will land beside the legacy implementation in a clean core. Before implementation, each current subsystem receives `keep`, `adapt`, `rewrite`, or `remove`, supported by a contract test or benchmark. No legacy class becomes foundational merely because it exists. A clean-repo rewrite was considered, but it would discard useful geometry, binning, graph-layout, XR placement, and demo evidence before measuring it. Incrementally extending current nodes was rejected because it would cement the inconsistent API and coupling.

### Prefer dependency integration over custom implementation

The project minimizes owned code. Before implementing a subsystem, the team searches the Godot Asset Library, maintained Godot/GDExtension ecosystems, relevant protocol SDKs, and established Python or web packages. A candidate is evaluated against semantic fit, maintenance health, license, security posture, API stability, Godot-version support, WebXR/web-export support, supported platforms, binary and transitive dependencies, bundle size, performance, testability, and ability to operate behind the project's normalized contracts. The decision record names candidates, records evidence, and selects `adopt`, `wrap`, `optional integration`, or `build minimal`.

Adopted packages remain upstream-shaped behind thin project-owned ports or adapters; their internal APIs do not become the public plotting contract. Configuration, composition, generated bindings, and upstream contribution are preferred to forks or local rewrites. Custom code is limited to the product's differentiating contracts, semantic normalization, spatial analytical behavior, and gaps no acceptable dependency covers. If a package is nearly suitable, contributing the missing capability upstream is preferred when practical.

Dependency-first does not mean dependency-at-any-cost. The standard-Godot and WebXR baseline remains usable without mandatory .NET or native binaries. A dependency incompatible with that baseline may power a declared optional native tier or companion service when the normalized contract preserves a functional baseline or explicit unavailable state. Security-sensitive operations such as authentication use host/platform providers rather than home-grown cryptography or credential storage.

The repository maintains a machine-readable dependency inventory and lock/version manifests appropriate to each ecosystem, plus a human-readable README table. Each entry declares purpose, owner/source, resolved or supported version, license, integrity/source policy, bundled/required/optional/development scope, transitive or binary implications, supported Godot/export/platform tiers, update policy, and replacement/fallback behavior. Release review includes vulnerability/license checks, upstream compatibility tests, notices/source obligations, and removal of unused packages.

### Define a retained plot specification as the center

The core model is `Figure -> View/Axes -> Layer`, with data references, transforms, scales, coordinates, marks, guides, and interaction state. A pyplot-like facade and a grammar-style builder both compile into the same serializable model. Renderers consume diffs of that model. Direct imperative mesh construction remains an escape hatch, not the public plotting abstraction.

### Separate pure core, Godot renderer, and input adapters

The pure core owns validation, mappings, scales, ticks, transformations, selection state, and plot diffs. The Godot adapter owns nodes/resources, meshes, labels, materials, picking IDs, and editor preview. Desktop and XR adapters translate device events into shared intents such as point, select, brush, navigate, and reset. Optional XR dependencies remain outside the base addon.

### Ship a pure typed-GDScript addon

The distributable core will contain GDScript, Godot resources, shaders, scenes, and assets only. It will load in standard Godot without the .NET editor, NuGet restore, compilation, or platform-specific binaries. C# consumers can instantiate and call the GDScript API through Godot's existing interop, but the project will not maintain parallel C# and GDScript implementations.

This is feasible because the chart renderer primarily uses APIs available directly in GDScript: `Node3D`, `MeshInstance3D`, `ImmediateMesh`/`ArrayMesh`, `MultiMesh`, materials, `Label3D`, resources, signals, arrays, dictionaries, JSON, files, and vector math. The current two-line `.gd` files are wrappers, not meaningful GDScript implementations, so this is a rewrite against contracts rather than a mechanical translation.

The present external .NET dependencies are handled explicitly: basic descriptive statistics are implemented and tested in the pure core; graph topological sort and approved layouts use bounded GDScript algorithms or an optional adapter; MSAGL layouts are not an MVP core requirement; circuit visualization is rewritten as a first-class GDScript specialized plot; and C# widget schema tooling remains outside core. A GDExtension may later be offered as an optional acceleration backend only after benchmarks prove a need and the GDScript implementation remains the functional baseline.

A C#-first addon was rejected because it requires Godot .NET, project compilation, and package restoration, contradicting frictionless Asset Library installation. Parallel implementations were rejected because behavioral parity and maintenance costs would dominate a small team. A mandatory GDExtension was rejected because binary distribution and platform/architecture support would make installation and XR portability harder.

### Treat correctness and performance as product behavior

Golden numerical tests cover domains, scales, ticks, bins, missing values, and deterministic transforms. Headless scene tests cover lifecycle and picking; image baselines cover representative plots; input conformance tests replay the same intent sequence across adapters. Performance budgets will be recorded by dataset size, update pattern, hardware class, render mode, and mono/stereo view before optimization work is accepted.

### Keep the demo downstream

A small gallery and interaction lab become the reference consumers. The current data room can later consume released APIs, but workspace orchestration, desktop capture, and generic widgets do not ship in core. Circuit visualization remains because it has an explicit plotting capability and acceptance contract.

The primary onboarding consumer is a focused analytical studio backed by deterministic recorded messages. Its minimal backend implements production contracts but no private schema, arbitrary-code endpoint, or alternate renderer path. Replay is the default so onboarding, documentation, CI, and research remain reproducible and offline; an optional live Jupyter path proves that real Matplotlib, pandas, Plotly, and Qiskit objects traverse the same boundary. The scene teaches connection context, catalog use, provenance, data-derived plotting, chart versus frame manipulation, compound views, embodied navigation, streaming recovery, and safe context switching. Opt-in study events measure task comprehension and interaction failures without collecting credentials, source code, notebook contents, private endpoints, or raw analytical values by default.

### Preserve circuits as semantic specialized plots

The Python companion adapts `qiskit.circuit.QuantumCircuit` through Qiskit's ordered `CircuitInstruction` data and `circuit_to_dag` APIs into a versioned, JSON-safe circuit payload. Godot does not interpret QPY directly: QPY is appropriate for full-fidelity transfer between Qiskit processes, while the Python adapter remains the trust and normalization boundary. OpenQASM 3 may be retained as source text/provenance or accepted by the Python service, but it is not the canonical visualization contract because conversion can lose Qiskit-specific structure.

The normalized circuit model preserves circuit/register/bit identity; ordered instructions; operation name, label, parameters and symbolic expressions; quantum/classical operands; controls and modifiers; measurement targets; conditions and supported control-flow regions; barriers/directives; global phase; timing/layout/calibration summaries where safely representable; and dependency edges/layers with their derivation. Unsupported custom instructions retain an opaque, inspectable semantic node and diagnostic rather than being mislabeled as a standard gate.

The renderer expresses a circuit as the same retained figure/view/layer system, extended with circuit marks and coordinates. Conventional wire-and-gate layout is the baseline. Spatial modes may use depth to expose dependency, hardware mapping, grouping, timing, or comparison, but must label the meaning of every dimension and never imply quantum state amplitude or probability without corresponding result/state data. Existing parser fixtures, layering behavior, gate/wire rendering, and layer scrubbing are migration evidence; their C#, QuikGraph dependency, lossy schema, destructive rebuilds, and gate-shape assumptions are not preserved as architecture.

### Adopt an original quiet-scientific-instrument visual language

Three web systems provide complementary references rather than templates to copy. Plotly contributes scientific familiarity, publication-ready 3D plots, explicit camera/navigation tools, hover inspection, and reset affordances. Observable Plot contributes a sparse data-first hierarchy, composable geometric marks, scale-derived guides, details on demand, and redundant color/symbol encoding. Apache ECharts contributes coherent light/dark themes, design-token consistency, strong normal/emphasis/select/disabled states, data zoom, and polished dashboard controls.

The product direction is a quiet scientific instrument placed in an analytical gallery: neutral low-contrast structure recedes; data marks carry controlled chroma; selected and manipulated objects gain redundant outline/shape/motion cues; labels feel like precise instrument annotations; and handles look physically operable without turning the graph into a game HUD. Depth, lighting, transparency, texture, and animation communicate grouping, focus, uncertainty, density, interaction, or spatial orientation only. Decorative depth that changes perceived values is prohibited.

Appearance is driven by semantic design tokens rather than renderer literals. Tokens cover data palettes and ramps, surfaces, guides, typography, line/tube radii, point/gate sizes, corner radii, depth layers, emissive focus, state transitions, target padding, viewing-distance classes, density/LOD, and comfort motion. Themes resolve tokens for light, dark, high-contrast, color-vision-safe, presentation, and WebXR-performance profiles while preserving data mappings.

The asset kit combines procedural geometry for value-bearing marks and guides with curated reusable resources for handles, slider tracks/thumbs, grab anchors, slice planes, selection volumes, tooltips, legends, reset/orientation landmarks, and circuit gates. Assets are source-controlled in editable/code-native form where practical, use shared materials and meshes, declare real-world dimensions and pivots, and provide low/medium/high or procedural LODs. Branded shapes, palettes, icons, or trade dress from reference products are not copied.

User-authored visuals plug in through semantic asset roles rather than subclassing chart renderers. An asset pack is a Godot resource plus a manifest that maps stable roles to a `Mesh`, `PackedScene`, procedural provider, material profile, or icon. Blender and other DCC tools export glTF/GLB into this pack; Godot users may author `.tres`, `.res`, `.tscn`, meshes, shaders, and procedural GDScript providers. The manifest declares bounds, pivot, orientation, scalable axes, material slots, collision/picking policy, state variants, LODs, performance class, license, and provenance. Import validation previews every role and substitutes core fallbacks for missing or invalid assets.

Theme packs compose tokens, fonts, materials, shaders, icons, and asset-role mappings. A visual asset does not own values, labels, selection state, or interaction logic; the renderer injects those through documented sockets and material parameters. This keeps custom Blender models interchangeable across plot types and prevents a theme from changing analytical behavior. The initial catalog and priorities live in `asset-catalog.md` beside this design.

### Separate frame, plot, binding, and session state

A frame is a persistent spatial viewport with identity, transform, bounds, chrome, theme reference, visibility/lock state, content binding, and local view state. It does not own the publisher or source data. A binding connects the frame to a static plot, live plot identifier, stream/topic, derived view, or snapshot and records representation policy. Plot state describes analytical content; frame state describes where and how that content is presented; session state describes a collection of frames, relationships, history, and restore behavior.

Published plot specifications are source-authored representations. Raw or semantically typed streams may advertise compatible representations. The binding policy distinguishes `follow_source`, `suggest_source`, `user_locked`, and `derived`: following a published “number of trials per year” line plot reproduces its line representation; selecting the underlying longitudinal data may allow the user to choose another compatible mark after preview and validation. Switching representation never silently mutates the publisher or discards the prior local configuration.

Frame input has explicit `content`, `frame`, and `layout` modes. Content mode routes pointing, zoom, brushing, handles, and inspection into the plot. Frame mode exposes move/rotate/resize/dock/grab handles around the frame. Layout mode operates on a multi-selection for align, distribute, group, link, compare, or delete. Direct grabbing may temporarily enter frame mode, but every operation has visible capture, constraints, preview, commit/cancel, undo, and reset behavior. This prevents scroll, pinch, or two-hand gestures from ambiguously resizing a frame when the user intended to zoom its axes.

The addon owns a transport-neutral stream catalog and binding contract, not a particular message bus. Integrations publish source identity, topic, schema/spec, semantic fields, suggested representations, units, cadence, freshness, permissions, and status. Frames survive disconnects with an explicit stale/paused/error state, last-good revision, and reconnect policy. The existing create/delete, chart picker, size presets, topic routing, manual chart lock, move mode, placement preview, and workspace save/restore flows provide migration evidence but move out of demo-specific services.

### Represent compound figures inside frames

A frame hosts one figure, and a figure may contain one or many views. Multi-view composition is therefore different from grouping frames: views in a compound figure share one frame lifecycle, chrome, transform, theme context, and export boundary, while each view retains its own plot layers, binding, local state, status, and provenance. Independent frames remain appropriate when views need separate placement, permissions, lifecycle, or embodied scale.

The composition tree supports rows, columns, regular grids, named mosaics with spanning cells, overlays/layers, insets, tabs/pages, and explicitly authored spatial arrangements. A 2×2 quad plot is a grid preset, not a special chart type. Layout constraints include weights, minimum/ideal sizes, aspect policy, gaps, padding, alignment, shared guide regions, and responsive breakpoints. For XR, a flat grid may curve, paginate, or expand into a spatial arrangement only through an explicit presentation policy that preserves view order and relationships.

Source-published multi-view specifications normalize directly into the figure composition tree. Session composition creates a new local compound figure by inserting existing plots, snapshots, or live bindings into view slots. It records source provenance per view and composition provenance for the figure, never masquerading as a publisher-authored layout. Shared scales, axes, legends, cursors, selections, filters, parameters, and playback require declared compatibility and link direction; coincident placement alone does not imply shared semantics.

### Catalog data independently from published plots

The session catalog has separate entries for published plots and data objects. A published plot already contains representation intent and normally opens under `follow_source`. A data object contains values and semantics but no authoritative visual representation; opening it starts a local plot-building workflow that chooses fields, transforms, encodings, marks, guides, and interaction parameters and records those choices as session-authored provenance.

Python objects remain behind the companion-service boundary. A pandas DataFrame, Series, NumPy array, Arrow table, xarray object, or supported dataframe-protocol object is advertised through a stable opaque handle with kernel/session identity, object revision or fingerprint, schema, shape, index/coordinate metadata, semantic types, units where known, null/non-finite statistics, bounded preview, capabilities, permissions, and freshness. Godot requests bounded pages, columns, aggregates, samples, or a materialized snapshot through the adapter; it never executes arbitrary Python expressions supplied by a message and never deserializes Python object memory or pickle.

Bindings distinguish `live_reference`, `snapshot`, and `derived`. A live reference re-queries declared revisions; a snapshot freezes a materialized version; a derived dataset records a safe declarative transformation graph over one or more inputs. Plot creation may recommend compatible mappings from semantic types, but the user confirms the representation. Large or remote data uses projection, filtering, aggregation, sampling, pagination, and backpressure rather than full eager transfer.

The first implementation consumes data exposed by Python/Jupyter and data already produced by chart interactions such as selections or aggregates. General in-session data authoring and generation—manual tables, formulas, simulation, editing, joins, or procedural producers—is a follow-up subsystem, but it must implement the same data descriptor, revision, provenance, capability, and binding contracts so plots do not care where data originated.

File selection and import are likewise future acquisition capabilities, not chart-renderer responsibilities. A desktop/native picker may yield an authorized path or file handle, while a WebXR/browser picker typically yields an uploaded browser file/blob; remote Jupyter may require upload to a kernel-visible staging area rather than access to the user's local path. The session creates a transport-neutral import request containing a capability-scoped file reference, media/format hint, size and checksum, requested table/sheet/range, processor target, and lifecycle policy. An authorized Python/Jupyter processor converts `.xls`/`.xlsx`, CSV, Parquet, Arrow, or future sources into the same data descriptor/handle contract. Godot neither assumes filesystem topology nor requires Excel parsing in the core addon.

Acquisition is staged and explicit: select, inspect metadata, choose processor/import options, preview discovered datasets such as workbook sheets, confirm materialization, then register catalog entries. File bytes, credentials, macros, formulas, external links, and processor logs are subject to permissions, size/time limits, quarantine policy, cancellation, cleanup, and provenance. An imported table is indistinguishable to plotting workflows from a DataFrame that was already present, except for its acquisition provenance.

### Frame the product as an immersive notebook workbench

The initial experience should feel like a VR GUI for a Jupyter session, but the architecture remains federated and backend-neutral. The pure Godot addon owns plots, frames, compound figures, spatial interaction, local analytical state, catalogs, and transport-neutral contracts. A separately deployed companion adapter owns backend authentication, computational-session/document discovery, object inspection, execution requests, file staging, dataframe operations, and source-library adapters. The first adapter implements these contracts for Jupyter; a host application decides which adapters and capabilities to expose.

The Godot host owns the visible connection experience even when a companion, reverse proxy, operating-system broker, or enterprise identity provider performs the privileged authentication exchange. Connection profiles identify deployments and approved routes without serializing secrets. This permits local Jupyter, remote JupyterHub, and private-network deployments while allowing WebXR and native exports to report different authentication and network capabilities honestly. Godot does not bypass VPN, proxy, certificate, browser-security, or origin policy; it consumes routes and credential providers explicitly made available by the host environment.

Connection is separate from analytical context. After authentication, the user chooses among authorized servers/deployments, workspaces or projects where the backend supplies them, notebook documents, and kernel sessions. A persistent context indicator answers “which workspace, notebook, and kernel am I using?” while every frame retains its own source context. Switching the active browsing context never silently rebinds a live frame to a same-named notebook or variable: the user previews affected references and chooses to retain their original context, snapshot them, or confirm an identity-compatible rebind.

Catalog objects carry a provenance graph linking workspace/server, kernel/session, notebook/document, cell/execution, output, variable/data handle, plot revision, derived transformations, and spatial views. Users can navigate both directions: from a frame to the cell/data that produced it, and from a notebook/cell/data entry to its active frames and derived views. Kernel busy/idle/restarting/dead state, execution counts, stale outputs, errors, and environment/package versions are visible without implying that a plotted result is current when its producing state has changed.

Notebook actions are capability-gated commands, not arbitrary strings evaluated by the renderer. The baseline is read/discover/inspect. Optional integrations may authorize refresh, rerun a known cell, interrupt, restart, bind declared parameters, or execute a pre-registered command, with preview, identity, permission, confirmation, timeout, output capture, and audit provenance. Free-form code editing, terminal emulation, package installation, debugging, and full JupyterLab parity are future host-application concerns rather than chart-core requirements.

Generic contracts use backend, computational session, document, execution unit, output, object, artifact, environment, and command identities. Jupyter maps these to server, kernel/session, notebook, cell, output, variable/file, environment, and kernel command. Future adapters may map them differently or omit unsupported levels. Backend-specific metadata stays in namespaced extensions, and UI terminology may specialize labels without changing core state. No future adapter is selected until a separate compatibility study measures object/data interchange, streaming, provenance, authentication, execution safety, deployment, WebXR reachability, and user demand.

### Normalize Python plots at the producer boundary

Godot will consume a transport-independent `plot-message` envelope, not Python object memory, pickle, HTML/JavaScript, or a plotting-library-specific runtime. A companion Python package accepts supported objects and emits the normalized plot specification plus provenance. Message-bus integrations carry the same envelope over WebSocket, MQTT, NATS, ZeroMQ, Redis, or another chosen transport; routing and delivery semantics are not embedded in the plot model.

Adapters use the most semantic source available. Plotly figures expose data/layout JSON; Altair emits Vega-Lite JSON; Bokeh can serialize a document or standalone JSON item. Matplotlib has no equivalent stable semantic wire specification, so its adapter walks public `Figure`, `Axes`, container, line, collection, image, text, axis, legend, and 3D artist APIs after a draw to resolve transforms and defaults. Seaborn objects are compiled and adapted through their Matplotlib result initially, while retaining Seaborn provenance where available.

The receiver implements only the normalized contract. Each adapter declares `native`, `approximated`, `raster-fallback`, or `unsupported` for every source feature and emits diagnostics rather than silently changing meaning. A bounded PNG/SVG fallback can preserve appearance when semantics cannot be represented, but it is not considered an interactive chart. Raw source specs may be attached for diagnostics or round-trip tooling within size limits; they are never the Godot renderer's primary API.

### Model embodied analysis separately from source-chart controls

The normalized model separates analytical state from control presentation. Analytical parameters include scale domains, camera/view transform, visible slice or plane, filter predicates, thresholds, animation/time position, selections, and layer visibility. A control binding maps a handle, slider, dial, button, scroll gesture, or two-hand gesture to one parameter with domain, step, constraints, units, commit policy, and accessible label. Renderers can therefore present the same parameter as a desktop slider, controller-ray handle, direct-grab affordance, or WebXR fallback without changing the plot definition.

Entering a graph is not equivalent to orbiting a small chart. Each spatial view has explicit data-to-world transforms, physical scale, origin, bounds, floor/reference-space policy, entry pose, reset landmark, near/far detail policy, and navigation mode. User locomotion changes the observer pose; analytical zoom changes a scale domain; object manipulation changes the plot transform. These operations are distinct, reversible, and reported separately so walking through a graph never silently changes its data.

Matplotlib `mplot3d` informs 3D marks, projection, elevation/azimuth, shared views, axes, panes, and coordinate inspection. Plotly informs declarative camera, slider, animation, relayout, and restyle controls. Neither source contract limits the Godot experience: an adapter may import source controls, while the Godot plot can add native embodied controls and interaction state not present in the Python object.

WebXR uses the same intent and control-binding layer as native XR, behind a capability adapter. It negotiates reference space, input sources, hand tracking, and optional features at runtime; controller ray/select is the minimum immersive interaction path, while direct hand manipulation is progressive enhancement. The core must not require Godot XR Tools or a native OpenXR-only API.

## Risks / Trade-offs

- [A broad redesign can become endless architecture work] → Time-box the audit and spikes; require executable vertical slices and explicit exit criteria.
- [Supporting both GDScript and C# can distort the API] → Keep one canonical model, generate/maintain only thin idiomatic facades, and test parity.
- [Godot scene objects can leak into the pure model] → Enforce dependency direction and serialize core fixtures outside Godot.
- [XR performance varies widely] → Publish tested tiers and degradation policies instead of an unqualified point-count claim.
- [Picking every datum is memory-heavy] → Use renderer-managed IDs, spatial acceleration, aggregation, and level of detail.
- [A breaking reset loses early users] → inventory known usage, publish a mapping guide, and approve an adapter only when its support cost is justified.
- [Third-party plot schemas change between library versions] → Include producer library/version and adapter/version, maintain fixture matrices, normalize at the producer, and never promise arbitrary-version fidelity.
- [Plot objects can contain callbacks, custom artists, URLs, or unsafe serialized state] → Never accept pickle or executable code; reject external fetches by default; bound message/data/image sizes and nesting; use an allowlist of normalized marks and properties.
- [Users can become disoriented or accidentally distort data while standing inside a plot] → Separate locomotion, analytical zoom, and plot manipulation; provide landmarks, undo/reset, bounded transforms, comfort modes, and persistent indication of modified domains.
- [WebXR capabilities and performance vary by browser and headset] → Use runtime capability negotiation, a controller-ray baseline, progressive hand features, adaptive detail, and published device/browser tiers.
- [Rich 3D styling can obscure quantitative truth or exhaust WebXR budgets] → Require semantic justification for depth/effects, shared materials and batched meshes, theme-level effect budgets, accessibility checks, and representative stereo visual/performance baselines.

## Migration Plan

1. Freeze feature additions to legacy core; inventory APIs and known consumers.
2. Run audit/spikes and record the language, packaging, renderer, and compatibility decisions.
3. Build a scatter-plot vertical slice through specification, scale, renderer, and desktop/XR selection contracts.
4. Add remaining MVP marks, guides, streaming, linked interaction, and release gates.
5. Publish a preview namespace/version alongside legacy code and migrate the gallery.
6. Decide whether to ship a bounded compatibility adapter; deprecate and then remove legacy/demo-owned core behavior.

Rollback is release-based: retain the last legacy tag and keep preview APIs versioned until the new release gates pass. Serialized plot specifications include a schema version and migrations.

## Open Questions

- Which message-bus transport is the first optional bridge over the now-defined transport-neutral session protocol?
- After Jupyter, which computational backends justify official adapters, and which should remain community integrations?
- Which first-release platforms and XR runtimes define the compatibility matrix?
- Are statistical transformations part of the MVP, or should the first release assume prepared columns?
- What measured dataset sizes and frame-time targets define desktop and stereo-XR tiers?

These are implementation decision gates, not unresolved architectural boundaries. Phase 1 may begin with recorded in-process transport, prepared-column statistics, the clean standard-Godot desktop target, and benchmark scenes while evidence is gathered for the first network bridge, XR matrix, statistical scope, and measured budgets.

## Sequencing of the extended analytical-client capabilities

The analytical table, session protocol, session parameters/checkpoints, and execution planner are foundation contracts because they affect identity, revision, permissions, transfer, persistence, and every backend integration. Their minimal vertical slices precede broad chart coverage. Sharing/publication and the extension/command/diagnostics platform follow those stable contracts. Collaboration, governance, annotations, scheduled delivery, and richer storytelling may ship incrementally, but actor, scope, permission, annotation, and audit fields are reserved in foundational identities so those features do not require a destructive schema reset.

### Integrate geospatial models instead of building a GIS engine

Geospatial support uses a layered dependency strategy. deck.gl is the primary semantic reference for composable geospatial layers, per-layer coordinate systems/origins, views, units, picking, and tile/LOD behavior; its JavaScript implementation is not itself assumed to run inside standard Godot. The maintained 3D Tiles for Godot/Cesium ecosystem is evaluated as an optional native integration for terrain, photogrammetry, and city-scale tiles, subject to license, Godot-version, platform, precision, authentication, and WebXR tests. MapLibre-compatible tiles/styles and other providers are adapters rather than canonical model dependencies.

Authoritative GIS work stays primarily in established companion-side packages: PROJ for coordinate/reference-frame transformations, GDAL for raster/vector formats and models, and GeoArrow/GeoParquet for columnar geometry interchange, with GeoPandas or query-engine integrations where they minimize custom work. Godot owns normalized geospatial descriptors, retained analytical layers, session interaction, selection identity, local precision/rebasing presentation, and XR controls. It does not implement a general CRS database, GIS format suite, spatial database, or globe/terrain streamer from scratch.

The first geospatial surface is intentionally narrow: common point, path, polygon, raster, and aggregate layers; explicit CRS/origin/units; a planar or local view; picking and attribute inspection; linked selection/filtering; and dependency capability discovery. Everything else is progressive integration. If installed packages expose globe views, 3D Tiles, terrain, point clouds, routing, geocoding, advanced spatial predicates, additional formats, or offline caches, the workbench may surface those capabilities through normalized adapters. Their absence is a normal supported configuration, not a gap to fill with bespoke algorithms.

The first Godot-facing candidate matrix includes 3D Tiles for Godot, Geodot, `godot-gis`, a lightweight MapTileProvider-class addon, and maintained terrain packages. These solve different problems and are not interchangeable: 3D Tiles targets streamed Earth-scale 3D content; Geodot exposes GDAL-backed local raster/vector sources; `godot-gis` offers a Rust/GDExtension geometry, PROJ, spatial-index, vector-tile/format, and renderer toolkit; lightweight tile providers cover planar imagery with less machinery; terrain packages render bounded heightmaps without providing GIS semantics. We may adopt more than one as optional adapters, but the core never presents their union as one enormous mandatory API. Host applications remain free to use provider-specific nodes directly beside normalized chart layers.

BlenderGIS belongs to the authoring pipeline rather than the runtime architecture. It can turn shapefiles, rasters, GeoTIFF elevation, OSM data, and web basemaps into editable terrain and scene assets, reducing our asset-tooling burden. Exported GLB geometry alone loses important GIS context, so the authoring template carries a sidecar/asset manifest with CRS, local origin, axes, scale, vertical reference, bounds, accuracy, source revisions, attribution/licenses, provider restrictions, and generation settings. BlenderGIS itself is not redistributed with the addon, and its GPL license or service credentials do not silently transfer into runtime dependencies.

Geospatial coordinates never become untyped `Vector3` values at the contract boundary. Source CRS, axis order, units, datum, vertical reference, epoch, accuracy, transformation provenance, and local rendering origin remain explicit. Earth-scale content uses local tangent/camera-relative or hierarchical precision strategies while preserving authoritative double-precision coordinates outside Godot scene transforms. Basemap and tile licensing, attribution, privacy, credentials, caching, and export restrictions are product behavior, not documentation afterthoughts.
