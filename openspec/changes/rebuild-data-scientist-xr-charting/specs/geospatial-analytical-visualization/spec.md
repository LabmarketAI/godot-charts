## ADDED Requirements

### Requirement: Minimal geospatial public surface
The core addon SHALL expose the smallest normalized geospatial surface needed to display, inspect, select, link, filter, navigate, and annotate geospatial data supplied by approved dependencies. The baseline SHALL consist of explicit coordinate metadata, common feature geometry, a bounded set of analytical layers, map/local views, feature identity, picking, guides, and capability discovery. Globe/planet rendering, arbitrary CRS transformation, GIS file parsing, tile generation, geocoding, routing, topology editing, general spatial databases, advanced geoprocessing, photogrammetry, and offline map production SHALL NOT be reimplemented in core and SHALL appear only through optional adapters that already provide them.

#### Scenario: Backend lacks an advanced GIS capability
- **WHEN** a user or source requests routing, geocoding, topology repair, tile generation, or another operation not advertised by installed adapters
- **THEN** the workbench reports the capability as unavailable or offers an installed provider and does not emulate a partial implementation in GDScript

#### Scenario: Add an optional geospatial provider
- **WHEN** an adapter supplies terrain, globe, additional CRS, spatial operations, or specialized formats
- **THEN** the core exposes only its normalized capabilities and results while provider-specific configuration remains in namespaced integration metadata

### Requirement: Dependency-first geospatial architecture
The project SHALL treat geospatial visualization as an integration of established models rather than a new GIS implementation. The semantic layer/view/coordinate approach SHALL be evaluated against deck.gl; Godot-native 3D Tiles/Cesium integrations SHALL be evaluated for optional terrain and city-scale content; and companion-side PROJ, GDAL, GeoArrow/GeoParquet, GeoPandas, and related maintained packages SHALL be evaluated for CRS transformation, format handling, spatial computation, and interchange. Adoption decisions SHALL follow the project dependency scorecard and SHALL preserve a pure-GDScript/WebXR baseline through normalized contracts and declared fallbacks.

#### Scenario: Existing package satisfies a geospatial operation
- **WHEN** an approved maintained companion or Godot package provides correct CRS transformation, tiling, geometry validation, spatial indexing, or terrain streaming
- **THEN** the project wraps or configures it through normalized contracts instead of recreating the operation in GDScript

#### Scenario: Native tiles plugin lacks WebXR support
- **WHEN** an otherwise approved Godot geospatial plugin cannot run in web export
- **THEN** it remains an optional native tier and WebXR uses an advertised raster/vector/geometry/remote-render fallback without changing plot semantics

### Requirement: Godot geospatial integration matrix
The initial dependency survey SHALL evaluate, at minimum, 3D Tiles for Godot for Cesium Native/3D Tiles streaming; Geodot for GDAL-backed raster/vector access; `godot-gis` for Rust/GDExtension geometry, PROJ transformations, spatial indexing, formats, vector tiles, and RenderServer integration; MapTileProvider or a maintained equivalent for lightweight raster map tiles and caching; maintained Godot terrain packages for bounded heightmap presentation; and BlenderGIS for offline geospatial asset authoring. Each candidate SHALL be classified by supported Godot or Blender versions, maintenance/release health, license obligations, language and binary model, transitive libraries, supported operating systems, standard-editor installation, web export/WebXR where applicable, authentication/provider coupling, coordinate/precision model, metadata and picking access, cache/offline policy, performance, public API stability, generated-asset provenance, and smallest useful adapter boundary. Survey results SHALL be recorded in the dependency inventory and SHALL not imply adoption.

#### Scenario: Evaluate Geodot
- **WHEN** Geodot is considered for local GIS file access
- **THEN** its GDExtension/GDAL packaging, GPL license implications, platform builds, web-export status, supported formats, filtering/cropping behavior, and ability to remain an optional adapter are recorded before selection

#### Scenario: Evaluate godot-gis
- **WHEN** `godot-gis` is considered as the native geospatial utility or renderer adapter
- **THEN** its Rust/Godot GDExtension versions, MPL-2.0 obligations, PROJ and Rust dependency graph, feature flags, supported geometry/format/index/renderer APIs, binaries/platforms, web-export status, precision, performance, and compatibility with normalized identities are tested before selection

#### Scenario: Evaluate 3D Tiles for Godot
- **WHEN** 3D Tiles for Godot is considered for globe, terrain, imagery, buildings, photogrammetry, or point-cloud content
- **THEN** its Cesium Native/GDExtension or module architecture, Apache-2.0 license, provider/private-source support, credential flow, precision modes, metadata/picking surface, networking/cache behavior, Godot compatibility, and WebXR fallback are tested before selection

#### Scenario: Evaluate a lightweight tile provider
- **WHEN** a pure-script or web-compatible tile addon can satisfy planar basemap needs
- **THEN** it is evaluated separately from globe/terrain engines so the minimal WebXR path does not inherit unnecessary native or provider dependencies

### Requirement: Blender geospatial authoring pipeline
The asset-authoring workflow SHALL evaluate BlenderGIS as an optional external tool for importing geospatial vectors, rasters, GeoTIFF elevation, OpenStreetMap data, basemaps, and terrain into editable Blender scenes before approved glTF/GLB export. The workflow SHALL define how source CRS, local origin, scale, north/up axes, vertical reference, bounds, accuracy, source/provider attribution, license, generation settings, and source revision are recorded in a sidecar or asset-pack manifest because ordinary mesh export is not sufficient geospatial provenance. BlenderGIS code SHALL NOT be bundled into the runtime addon, and generated assets SHALL undergo independent license and provider-terms review.

#### Scenario: Author terrain in BlenderGIS
- **WHEN** an artist imports elevation and imagery and exports a bounded terrain asset for Godot
- **THEN** the asset validator checks mesh scale/orientation/origin and requires declared CRS, bounds, vertical reference, source datasets, attribution/license, generation settings, and permitted runtime/export use

#### Scenario: Blender source requires an API key
- **WHEN** BlenderGIS accesses a provider such as an elevation or basemap service requiring credentials
- **THEN** credentials remain in the authoring environment, are excluded from Blender/Godot assets and manifests, and provider caching and derivative-work terms are recorded

### Requirement: Adapter-owned provider interaction
Godot geospatial packages SHALL be consumed through narrow adapters that map normalized view, source, camera, feature identity, picking, status, attribution, authentication reference, and cache controls to the provider where supported. The core SHALL not depend on provider node types, tokens, URLs, or serialized resources, and applications MAY interact directly with an installed provider for capabilities outside the chart library without requiring the chart library to mirror its complete API.

#### Scenario: Host uses a provider-specific feature
- **WHEN** a host application configures a provider feature outside the normalized chart capability
- **THEN** the host may retain a provider reference while charts use only normalized shared identities and state, and absence of that feature does not expand the core API

### Requirement: Explicit coordinate reference semantics
Every geospatial layer SHALL declare a coordinate reference system or an explicitly local/unknown coordinate space; axis order; horizontal and vertical units; datum/reference frame; optional coordinate epoch; altitude/height reference; dimensionality; valid area; and source accuracy where supplied. The model SHALL distinguish longitude/latitude/height, projected coordinates, Earth-centered Earth-fixed coordinates, local east-north-up or other tangent frames, tile coordinates, screen coordinates, and non-geographic Cartesian analytical coordinates.

#### Scenario: Receive ambiguous latitude and longitude
- **WHEN** a source provides two geographic-looking columns without declared axis order or CRS
- **THEN** the adapter requests confirmation or rejects geospatial interpretation rather than guessing and plotting a plausible but potentially wrong location

### Requirement: Authoritative transformations and provenance
CRS, datum, vertical, and epoch transformations SHALL be executed by an approved authoritative geospatial library or backend service when required beyond a validated minimal transformation. Every result SHALL record source/target CRS, operation or pipeline, library/database version, grids/resources, axis/unit changes, area of use, declared or estimated accuracy, warnings, and whether a ballpark transformation was used. Godot SHALL not silently substitute Web Mercator or WGS84.

#### Scenario: Transformation requires an unavailable grid
- **WHEN** an accurate datum or vertical transformation requires a missing resource
- **THEN** the operation fails or uses an explicitly confirmed lower-accuracy alternative with visible accuracy/provenance diagnostics

### Requirement: Geospatial layer grammar
The retained plotting model SHALL define a small baseline of point/text, path, polygon, raster/image, and aggregate grid/density layers. Additional arcs/trips, vector/raster tiles, terrain/elevation, point clouds, 3D Tiles, globe, or scene content SHALL be optional capabilities supplied by approved adapters. Layers SHALL declare coordinate system/origin, data/attribute mappings, units, elevation/extrusion meaning, time, visibility range, blending/occlusion, picking, styling, LOD, source attribution, and permissions only as applicable to their advertised capability.

#### Scenario: Extrude a choropleth
- **WHEN** a polygon layer uses height to encode a measure
- **THEN** the height scale, units, baseline, aggregation, missing-value policy, and legend are inspectable and terrain height is not confused with the encoded value

### Requirement: Map, globe, local, and embodied views
Geospatial figures SHALL support declared planar map, globe, local tangent/scene, and embodied region presentations where dependencies and performance tiers permit. Projection, camera, scale/zoom, north/up orientation, origin, Earth curvature, vertical exaggeration, world scale, recentering, and entry/reset pose SHALL be explicit. Locomotion, map navigation, analytical filtering, and whole-frame manipulation SHALL remain distinct.

#### Scenario: Enter a city-scale dataset
- **WHEN** a user expands a local geospatial view to embodied scale
- **THEN** a visible origin, north/up reference, scale bar, coordinate readout, safe entry pose, recenter action, and accuracy/LOD status preserve orientation and interpretation

### Requirement: Earth-scale numerical precision
The renderer SHALL use a documented geospatial-to-Godot precision strategy such as stable local origins, tangent frames, hierarchical transforms, camera-relative coordinates, or rebasing. Source coordinates SHALL retain sufficient precision outside single-precision scene transforms, and rebasing SHALL preserve feature identity, selections, annotations, and analytical measurements.

#### Scenario: Recenter a distant region
- **WHEN** navigation moves beyond the precision budget of the active local origin
- **THEN** the renderer rebases or changes tiles without visible feature jumps, selection loss, or mutation of authoritative source coordinates

### Requirement: Tiled, progressive, and offline-aware sources
Raster, vector, elevation, point-cloud, and 3D tile sources SHALL expose scheme, CRS, bounds, levels/resolution, content type, style, authentication, attribution, cache/expiration, request limits, availability, offline policy, and provenance. Loading SHALL be view-dependent, cancellable, prioritized, bounded, and compatible with the execution-planning and session protocols. Missing tiles SHALL not be interpreted as zero-valued data.

#### Scenario: Navigate rapidly across a tiled map
- **WHEN** the camera leaves the region of outstanding requests
- **THEN** obsolete requests are cancelled or deprioritized and the current region loads under bounded concurrency and cache policy

### Requirement: Geospatial data interchange
The companion SHALL normalize supported GeoArrow/GeoParquet, GeoJSON, simple-feature, raster, and tile metadata into versioned data descriptors without requiring Godot to parse every GIS format. Geometry columns SHALL retain type, CRS, edge/interpolation semantics, dimensions, feature identity, validity, bounds, attributes, nulls, and provenance. Large geometry SHALL use bounded columns/pages, tiles, generalization, or remote execution.

#### Scenario: Open a GeoParquet dataset
- **WHEN** a supported companion exposes GeoParquet geometry and attributes
- **THEN** Godot receives a bounded GeoArrow-compatible descriptor and selected geometry/attribute batches with CRS and feature identity intact

### Requirement: Spatial queries and derived analysis
The baseline SHALL support viewport/bounding-region filtering and selection linkage where supplied geometry permits. Approved backends MAY advertise additional declarative spatial predicates and operations such as point-in-polygon, nearest/within-distance, intersection, clipping, buffer, dissolve, spatial join, aggregation by region/grid, route/trajectory segmentation, and raster sampling. Core SHALL forward normalized plans and results rather than implement a general geoprocessing engine. Operations SHALL declare planar versus geodesic semantics, units, tolerance, validity handling, approximation, execution location, limits, and provenance.

#### Scenario: Select points within a drawn region
- **WHEN** a user commits a spatial selection volume or polygon
- **THEN** the normalized predicate executes using declared CRS and planar/geodesic rules and returns a selection or derived dataset linked to its source features

### Requirement: Temporal and streaming geospatial data
Geospatial layers SHALL support time instants, intervals, trajectories, event streams, time windows, playback, trails, and revision-safe updates with timezone/time-standard provenance. Spatial and temporal filtering SHALL compose with session parameters, snapshots, checkpoints, and linked non-geospatial views.

#### Scenario: Scrub a vehicle trajectory
- **WHEN** a user changes the shared time-window parameter
- **THEN** the path/trail, current positions, linked charts, and table update through one transactional parameter revision with declared interpolation

### Requirement: Feature inspection, measurement, and annotation
Users SHALL be able to pick features and inspect attributes, coordinates in approved representations, source/CRS, altitude, time, uncertainty/accuracy, selection membership, and provenance. Distance, area, bearing, elevation/profile, and coordinate measurements SHALL declare geodesic/projected/local method, units, accuracy, and terrain/ellipsoid reference. Annotations SHALL remain anchored through LOD and origin changes where identity permits.

#### Scenario: Measure distance on a globe
- **WHEN** a user measures between geographic points
- **THEN** the result identifies the geodesic or other chosen method, ellipsoid/CRS, units, and accuracy rather than reporting raw Godot scene distance as Earth distance

### Requirement: Basemap attribution, licensing, and privacy
Every external basemap, tile, terrain, imagery, geocoder, or 3D-content provider SHALL declare license, attribution text/logo/link requirements, usage limits, credential policy, caching/offline restrictions, privacy implications, and permitted export/share behavior. Attribution SHALL remain visible in desktop and immersive presentations and in applicable exports. Private coordinates and requests SHALL follow host redaction and network policy.

#### Scenario: Export a view with third-party tiles
- **WHEN** provider terms permit image export
- **THEN** required attribution is included and the publication manifest records the provider and applicable content restrictions

### Requirement: Geospatial accessibility and uncertainty
Geospatial views SHALL provide non-color encodings, readable legends, textual/table alternatives, keyboard-accessible navigation, named-place/region context where supplied, and summaries of visible extent and selected features. Positional accuracy, uncertainty regions, incomplete coverage, stale imagery, generalized geometry, and approximate transformations SHALL be representable rather than hidden.

#### Scenario: Display uncertain locations
- **WHEN** observations include horizontal or vertical uncertainty
- **THEN** the view can render and inspect uncertainty bounds and does not present exact point placement without qualification

### Requirement: Geospatial conformance and benchmark fixtures
The project SHALL maintain fixtures for CRS/axis order, dateline and poles, globe/map/local transitions, altitude/vertical datums, large coordinates and rebasing, invalid geometries, polygons with holes, antimeridian paths, raster/vector/terrain tiles, GeoArrow interchange, spatial queries, time trajectories, attribution, offline/missing tiles, privacy, and desktop/native-XR/WebXR performance tiers.

#### Scenario: Render an antimeridian trajectory
- **WHEN** a path crosses longitude 180 degrees
- **THEN** its declared wrap/split/geodesic behavior is correct and it does not draw an unintended line across the rest of the map
