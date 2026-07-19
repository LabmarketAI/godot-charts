## ADDED Requirements

### Requirement: Blender-authored canonical GLB assets
Official non-procedural chart asset packs SHALL be authored or finalized in Blender with metric scale, declared pivots, stable object names, semantic material slots, collision proxies, LOD collections, and reproducible GLB export settings.

#### Scenario: Author a domain handle
- **WHEN** a domain-handle asset is created
- **THEN** its Blender scene declares the semantic role, center pivot, interaction anchor, visible mesh, collision proxy, focus/active material sockets, LOD variant, dimensions, and WebXR budget before export

#### Scenario: Reject decorative chart geometry
- **WHEN** an asset adds bevels, shadows, textures, animation, or transparency that can change perceived chart values or obscure controls
- **THEN** validation or visual review rejects the asset or requires a semantically neutral alternative

### Requirement: ComfyUI support boundary
ComfyUI-generated outputs MAY be used for concept boards, material studies, texture inputs, icon references, or review alternatives, but they SHALL NOT become official chart geometry until finalized through the Blender and Godot asset validation pipeline.

#### Scenario: Generate a material study
- **WHEN** ComfyUI produces candidate material swatches for control handles
- **THEN** the selected swatch is documented as reference/provenance and mapped to semantic material tokens without baking interaction semantics into an image

#### Scenario: Generate a GLB candidate
- **WHEN** a local generative pipeline emits a GLB candidate
- **THEN** it is treated as an imported draft and must pass Blender cleanup, naming, pivot, collision, LOD, budget, license, and Godot validation before it can ship

### Requirement: Semantic asset manifest
Every official asset pack SHALL include a versioned manifest mapping stable role ids to GLB scenes, object paths or provider entries, dimensions, pivots, forward/up axes, material sockets, collision/picking shapes, state support, LODs, batching compatibility, performance tiers, license, author, and source provenance.

#### Scenario: Load a partial pack
- **WHEN** a pack provides GLB assets for controls but not marks
- **THEN** the provider resolves control roles from the pack, resolves missing mark roles through the deterministic fallback chain, and reports structured diagnostics

#### Scenario: Replace a bar asset
- **WHEN** `mark/bar` is backed by a GLB asset
- **THEN** the manifest identifies the baseline pivot and value axis so renderers preserve baseline, height, identity, selection, and inspection behavior

### Requirement: Asset validation gate
The project SHALL validate official GLB-backed assets for role coverage, object naming, pivots, dimensions, material sockets, collision proxies, triangle and material budgets, LOD availability, WebXR compatibility, license/provenance, import warnings, and deterministic fallback behavior.

#### Scenario: Missing collision proxy
- **WHEN** an interactive control asset lacks a declared collision or picking proxy
- **THEN** the validator fails that role and runtime resolves the procedural fallback instead of exposing an unselectable control

#### Scenario: WebXR budget exceeded
- **WHEN** a GLB role exceeds the active WebXR triangle, material, transparency, or animation budget
- **THEN** the WebXR tier selects a lower LOD or fallback while preserving role, state, value, and picking identity

### Requirement: Professional visual polish gate
Official chart assets SHALL meet a documented polish standard before artist handoff or runtime adoption. The standard SHALL cover intentional smooth/flat shading, bevels on appropriate exposed edges, weighted/custom normals for hard-surface polish, clean topology, semantic materials, shader restraint, readable silhouettes, and theme fit. Assets SHALL NOT ship with accidental low-poly faceting, muddy normals, toy-like materials, missing collision proxies, or temporary placeholder appearance.

#### Scenario: Curved control looks faceted
- **WHEN** a rounded handle, button, thumb, point, or cursor visibly shows unintended polygon facets at the target desktop or headset viewing distance
- **THEN** the asset fails review until its geometry, shade-smooth settings, auto-smooth/sharp-edge treatment, or normals are corrected within budget

#### Scenario: Hard-surface asset has muddy shading
- **WHEN** a beveled panel, bar, bounds element, or control has broad faces that appear warped because normals are averaged across hard edges
- **THEN** the asset must use corrected split/weighted normals or adjusted bevel/hard-edge settings before acceptance

#### Scenario: Polish changes analytical meaning
- **WHEN** bevels, shadows, glossy highlights, transparency, or shader effects change a user's reading of a value boundary, baseline, endpoint, domain handle, or uncertainty mark
- **THEN** the polish treatment is rejected or limited to non-value-bearing surfaces

### Requirement: Structured asset prompts
Every Blender MCP, artist handoff, or generated-asset prompt for official chart components SHALL include the semantic role, chart function, diegetic scale, interaction vocabulary, lookbook theme, shape/silhouette, material and shader policy, professional polish instructions, accessibility baseline, performance/fallback constraints, and negative constraints. Prompts SHALL define visible geometry and collision/picking targets separately.

#### Scenario: Prompt omits spatial scale
- **WHEN** an asset prompt describes a chart control without physical dimensions, intended viewing distance, or interaction target size
- **THEN** the prompt is incomplete and must be revised before authoring begins

#### Scenario: Prompt omits accessibility cues
- **WHEN** an interactive asset prompt relies on color alone or omits focus, target size, alternate input, or accessible metadata requirements
- **THEN** the prompt is incomplete and must be revised before authoring begins

#### Scenario: Generated draft has no role contract
- **WHEN** ComfyUI or another generated-asset tool produces a visually interesting GLB or concept without semantic role, pivot, collision, material sockets, and fallback constraints
- **THEN** it remains a reference draft and cannot enter the official asset pack until restated as a compliant Blender/Godot asset brief

### Requirement: Chart component production set
The first production pass SHALL cover P0 structural guides, point/bar/line marks, frame and axis-domain controls, interaction-state overlays, WebXR ray cursor, and procedural fallbacks before adding decorative, advanced, or chart-family-specific assets.

#### Scenario: Review the visual asset gallery
- **WHEN** the P0 pack is opened in the gallery
- **THEN** each role is visible in its supported states with dimensions, pivot marker, collision preview, material sockets, provider source, fallback source, and WebXR tier status

#### Scenario: Use assets in a renderer
- **WHEN** a chart renderer or control requests an asset
- **THEN** it requests a semantic role through the provider and does not hard-code a GLB path, mesh resource, or theme color

### Requirement: Procedural fallback preservation
Every GLB-backed chart-critical role SHALL retain a typed-GDScript procedural fallback that can load in standard Godot and WebXR without Blender-authored assets, external services, native extensions, or generated textures.

#### Scenario: Asset pack unavailable
- **WHEN** the official GLB pack is missing, invalid, or disabled
- **THEN** charts remain readable and controls remain operable through procedural fallbacks with visible diagnostics
