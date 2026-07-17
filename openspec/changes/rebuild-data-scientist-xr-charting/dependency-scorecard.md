# M1 Dependency Scorecard

Status: active M1 decisions, updated 2026-07-16. Standard Godot and fixture-tool versions are pinned and exercised by the clean harness; optional integration versions remain future scorecard decisions.

## Decision criteria

Every dependency is assessed for semantic fit, maintenance, license, security posture, API stability, Godot and Web export support, binary/transitive requirements, package size, performance, testability, and a documented fallback. Product-specific contracts remain owned by this project even when implementation is delegated to a package.

## M1 decisions

| Need | Candidate | Decision | Rationale and fallback |
|---|---|---|---|
| Standard engine floor | Godot 4.6.3 stable | Adopt | The generated preview plugin and headless suite pass the official standard (non-.NET) Linux build. CI pins the official release URL and SHA-256. Newer 4.6 maintenance releases may replace it after the same gates pass; 4.7 remains a development compatibility target until stable. |
| JSON parsing/serialization | Godot `JSON` | Adopt | Built into standard Godot, works in GDScript and web exports, and adds no package. Wrap with project-owned schema/version/limit validation; parsing alone is not contract validation. |
| Runtime contract validation | Full third-party JSON Schema implementation | Build minimal for M1 | Validate only the published M1 envelope and normalized objects with path-aware structured diagnostics. Keep schemas standard JSON Schema so Python and CI can use mature validators. Re-evaluate a maintained Godot validator before expanding contracts. |
| GDScript tests | GdUnit4 | Adopt as development dependency | Maintained Godot 4 test framework with GDScript, scene, assertion, and mocking support. It must not ship in the runtime addon. Fall back to Godot-native headless test scripts if version/export compatibility blocks CI. |
| Bounded analytical table | Godot `Tree` behind a table adapter | Wrap for M1 | Multiple columns, selection, custom cells, and scrolling are built in. Only materialize the bounded visible/requested window; do not claim general dataframe virtualization. Replace the view without changing the table/selection contract if profiling fails. |
| Scatter rendering | Godot `ArrayMesh`/`MultiMesh` and rendering resources | Build minimal adapter | These are standard-Godot primitives and avoid native dependencies. The renderer owns batching and stable pick-ID mappings; a future accelerator must implement the same contract. |
| Model/resources/signals | Typed GDScript `RefCounted`/`Resource` and signals | Adopt | Native serialization and lifecycle fit the addon. Pure model objects remain scene-tree independent where possible. |
| Recorded session playback | Project-owned deterministic replay | Build minimal | Ordering, revisions, duplicate handling, limits, and stepping are product protocol semantics, not a generic bus. Network transports consume the same replay-tested envelope later. |
| Python fixture generation | Matplotlib 3.11.0, pandas 3.0.3, JSON Schema 4.26.0 | Adopt as fixture-only dependencies | Exact M1 versions are pinned in `tools/m1/requirements.txt` and run outside Godot to create and validate deterministic checked-in fixtures. No Python runtime is required by the addon or demo replay. The future companion package will maintain its own supported-version matrix. |
| Message bus/WebSocket | Existing demo bridge or a third-party transport | Defer; optional integration | M1 is transport-free. Evaluate maintained Godot WebSocket/message packages only after replay proves the protocol. Browser APIs and credentials must never leak into core. |
| XR interaction | Godot OpenXR/WebXR and XR Tools | Defer; optional integration | M1 defines device-independent intents only. Later adapters may wrap maintained XR packages while retaining desktop and capability-loss fallbacks. |
| Authentication/workspace selection | Godot HTTP/WebSocket/browser facilities plus provider adapters | Defer; optional integration | Authentication is backend/provider specific and security sensitive. Keep tokens out of plot contracts and persistence; define it with the live Jupyter slice. |
| GIS/native acceleration | Geodot, godot-gis, GDAL/PROJ and related packages | Defer; optional integrations | Valuable but outside M1 and often native/platform constrained. The geospatial scorecard and bounded proof-of-concept tasks already cover selection. |

## Immediate manifest policy

The runtime addon has no approved mandatory third-party dependency for M1 beyond standard Godot 4.6.3 or newer. Python fixture packages are pinned development-only dependencies. GdUnit4 remains an approved but not-yet-introduced development dependency; the current fallback is a native headless `SceneTree` suite. Optional integrations must live outside core, advertise capabilities at runtime, fail transparently, and leave the recorded demo functional when absent.

## Sources checked

- [Godot JSON documentation](https://docs.godotengine.org/en/stable/classes/class_json.html)
- [Godot Tree documentation](https://docs.godotengine.org/en/stable/classes/class_tree.html)
- [GdUnit4 repository](https://github.com/godot-gdunit-labs/gdUnit4)
