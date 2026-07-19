# Chart Asset Lookbook Research

This note identifies three look-and-feel directions users already recognize in data products, then translates them into concrete asset attributes for Godot spatial/XR chart components. These are references, not styles to copy. The goal is an original Labmarket visual system with a clear brief before Blender asset work begins.

## Sources Reviewed

- Plotly positions itself around interactive scientific, statistical, 3D, and web-first charts, with hover, zoom, pan, select, animation, crossfilter, WebGL/SVG rendering, and built-in templates including light, dark, ggplot2, and seaborn styles: https://plotly.com/graphs/ and https://plotly.com/python/templates/
- Observable emphasizes audience fit, actionable insight, approachable charts, and color palettes designed for readable, accessible categorical interpretation: https://observablehq.com/learn/what-is-data-visualization and https://observablehq.com/blog/crafting-data-colors
- Apache ECharts 5 frames its default visual redesign around storytelling, elegant defaults, color differentiation, contrast, harmony, color-blind distinguishability, reduced unnecessary axis ink, and dense-label handling: https://apache.github.io/echarts-handbook/en/basics/release-note/v5-feature/ and https://echarts.apache.org/handbook/en/concepts/style/
- IBM Carbon data visualization guidance emphasizes accessibility, harmony, carefully sequenced categorical palettes, sequential/diverging palettes, neutral chart chrome, concise labels, correct grid density, and redundant shape/pattern cues: https://v10.carbondesignsystem.com/data-visualization/color-palettes/ and https://www.ibm.com/design/language/data-visualization/design/basics/
- Financial Times Visual Vocabulary is useful as a chart-literacy reference for matching visual form to analytical intent rather than over-styling: https://github.com/Financial-Times/chart-doctor/blob/main/visual-vocabulary/README.md
- Apple Human Interface Guidelines describe materials as depth/layering tools, recommend using glass/translucency sparingly for functional layers, and warn that legibility must drive material choice: https://developer.apple.com/design/human-interface-guidelines/materials
- Material Design elevation guidance treats shadows and elevation as consistent spatial cues; its dark-theme guidance favors deep grays over pure black and restrained elevated surfaces for hierarchy: https://m1.material.io/material-design/elevation-shadows.html and https://design.google/library/material-design-dark-theme
- Godot shader guidance distinguishes standard materials from custom `ShaderMaterial`; unshaded render modes skip lighting and are useful where lighting-stable appearance matters: https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_shaders.html
- glTF 2.0 uses a portable metallic-roughness PBR material model with base color, metallic, roughness, alpha, normal, occlusion, and emissive properties: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html and https://www.khronos.org/gltf/pbr

## Lookbook A: Scientific Studio

Reference gravity: Plotly, scientific Python notebooks, WebGL 3D charts.

User response pattern:

- Familiar to analysts and scientists because it resembles notebook/web chart tooling.
- Supports exploration: hover, zoom, pan, select, rotate, and compare.
- Accepts visible 3D depth when it clarifies spatial or multidimensional data.

Aesthetic attributes:

| Attribute | Direction |
|---|---|
| Mood | precise, interactive, technical, inspection-first |
| Canvas | light neutral by default; dark variant for immersive focus |
| Data color | saturated but disciplined categorical colors; sequential ramps for quantitative mappings |
| Structure | visible axes, ticks, grid, and bounds, but subordinate to marks |
| 3D depth | legitimate depth cues; no decorative extrusion on non-spatial values |
| Materials | mostly matte/unlit or lighting-stable; limited gloss for controls only |
| Marks | clean spheres/discs, crisp bars, thin tubes/lines, optional transparent surfaces |
| Controls | instrument-like handles with clear hover/active state and precise constraints |
| Typography | technical, compact, readable at notebook and headset distances |
| Motion | state transitions and data updates only; no ambient animation |

Asset implications:

- Axis and grid assets should be exact, thin, and measurable.
- Domain handles should look like analytical instruments, not game pickups.
- Data marks need stable silhouettes under stereo rendering.
- Hover/selection should use outline, halo, or size in addition to color.
- Dark theme must preserve quantitative color ordering under headset lighting.

Material, shader, and skeuomorphism guidance:

- Use mild instrumental skeuomorphism only on controls: small bevels, grip grooves, recessed centers, or mechanical affordance rings can communicate grab/select behavior.
- Avoid skeuomorphic textures on data marks. A point should not look like glass, polished metal, rubber, or stone unless material itself is data.
- Prefer `StandardMaterial3D` or GLB PBR metallic-roughness with low metallic (`0.0-0.1`) and medium/high roughness (`0.55-0.9`) for controls and structural pieces.
- Use unshaded or lighting-stable materials for value-bearing color. Quantitative color must not depend on scene lights, reflections, or bloom.
- Use emissive accents only for active/focus states and keep them low enough to avoid bloom or color bleed in WebXR.
- Keep transparency rare: surfaces and selection volumes may use bounded alpha, but axes, ticks, marks, and handles should be opaque in the baseline.

## Lookbook B: Editorial Clarity

Reference gravity: Observable, Financial Times visual-literacy practice, restrained explanatory charts.

User response pattern:

- Feels approachable to mixed technical/non-technical audiences.
- Prioritizes immediate comprehension, annotations, labels, and narrative hierarchy.
- Avoids dense ornament and puts the main analytical message first.

Aesthetic attributes:

| Attribute | Direction |
|---|---|
| Mood | clear, calm, explanatory, human-readable |
| Canvas | warm or soft neutral, low visual noise |
| Data color | small set of memorable hues; one highlight color plus neutrals is common |
| Structure | minimal axes and sparse grid; remove nonessential chart chrome |
| 3D depth | shallow, only where interaction or spatial context requires it |
| Materials | flat/matte, low contrast structural elements |
| Marks | simple geometry with generous spacing and readable silhouettes |
| Controls | quiet until focused; visual hierarchy favors labels and annotations over controls |
| Typography | larger labels, direct labels preferred over complex legends |
| Motion | gentle reveal or transition when it explains a change |

Asset implications:

- Guide assets need lower-ink variants: partial grids, sparse ticks, soft bounds.
- Legend and annotation anchors become first-class assets.
- Selection/hover should clarify, not dramatize.
- Avoid complex bevels, glow, or sci-fi styling.
- Good fit for presentation and user-study modes.

Material, shader, and skeuomorphism guidance:

- Stay closest to flat design. Physical metaphors should be limited to obvious affordances like a pressed button or draggable thumb.
- Use soft matte materials, flat color, and minimal elevation. If an element floats, show it with spacing and contrast before shadow.
- Avoid glass, chrome, leather, paper grain, heavy bevels, lens effects, bloom, and animated shaders.
- Prefer unshaded materials for labels, guide anchors, swatches, and explanatory marks so screenshots and headset views remain consistent.
- Shaders should support simple reveal, fade, or outline states only when they explain focus or a data update.
- Any texture must be subtle and nonsemantic; direct labels, leader lines, and annotation panels carry the editorial tone more than material effects.

## Lookbook C: Enterprise Instrument

Reference gravity: IBM Carbon data visualization, Apache ECharts production dashboards.

User response pattern:

- Feels trustworthy for repeated operational use.
- Uses strong accessibility, palette discipline, status conventions, and consistent component states.
- Scales across many charts without each view feeling custom-designed.

Aesthetic attributes:

| Attribute | Direction |
|---|---|
| Mood | durable, systematic, accessible, dashboard-ready |
| Canvas | neutral light/dark surfaces with strict contrast targets |
| Data color | curated categorical sequence; sequential/diverging palettes by semantic type |
| Structure | standardized grid density, labels, legends, status, and alert colors |
| 3D depth | controlled and ergonomic; depth should support repeated work |
| Materials | functional matte surfaces; no decorative transparency where it hurts legibility |
| Marks | consistent role-driven geometry; accessible shapes/patterns where color is insufficient |
| Controls | clear state machine: normal, hover, focus, active, disabled, warning, error |
| Typography | concise labels; direct labels where possible; dense labels use deterministic hiding/truncation |
| Motion | bounded, interruptible, reduced-motion friendly |

Asset implications:

- Every asset role needs state variants and redundant non-color cues.
- Collision/picking proxies must be visible in validation and reliable in WebXR.
- Status colors should follow user expectations: error/warning/success are reserved.
- Theme tokens should separate data, structure, control, and status palettes.
- Best fit for default Labmarket production theme.

Material, shader, and skeuomorphism guidance:

- Use functional material hierarchy: background, chart structure, data, controls, alerts, and overlays are distinct token families.
- Keep skeuomorphism pragmatic. Controls may have raised/resting/pressed elevation cues, but data marks remain abstract and role-driven.
- Use shadows/elevation primarily in flat desktop or panel contexts. In spatial charts, physical separation should come from geometry, outline, and depth position before screen-space shadows.
- For dark mode, use deep grays rather than pure black to reduce visual vibration and allow subtle elevated surfaces.
- PBR should be conservative: non-metallic, rough, low-specular surfaces for most components; metallic is reserved for rare branded or demonstrative assets, not analytical defaults.
- Shader effects must have state names and budgets: `focus_outline`, `active_pulse_reduced`, `invalid_constraint`, `selected_outline`, `disabled_desaturate`.

## Material Vocabulary

These material families should be represented as theme tokens and Blender material slots rather than baked colors.

| Family | Purpose | Default material rule | Shader rule |
|---|---|---|---|
| `data/matte` | Value-bearing marks | unshaded or low-specular matte, tokenized base color | no lighting-dependent color shifts |
| `data/surface_translucent` | Surfaces, bands, volumes | bounded alpha, depth-safe, no shadows | no overlapping alpha stacks in WebXR |
| `structure/quiet` | axes, ticks, grids, bounds | neutral low-contrast matte | no emission, no animation |
| `control/body` | buttons, handles, sliders | slightly raised matte PBR, subtle bevel allowed | state changes through outline/size/color, not texture swaps |
| `control/focus` | focus ring, hover halo | high-contrast outline or halo, non-color cue | optional low-cost pulse with reduced-motion static fallback |
| `status/alert` | warning/error/success | reserved semantic colors plus icon/shape/pattern | no bloom-only alert |
| `panel/material` | legends, tooltips, annotation panels | opaque or thick translucent panel depending theme | preserve text contrast; avoid transparent text backplates in WebXR |
| `xr/ray` | pointer and cursor feedback | emissive/unshaded line or reticle | valid/invalid/active states must be distinguishable without hue alone |

## Skeuomorphism Rules

- Use skeuomorphism for **learnability of controls**, not for decoration.
- Good: grab grooves on a handle, a pressed-state button depression, a slider thumb with an obvious contact surface, a reset landmark shaped as a stable orientation marker.
- Bad: glass data points, metallic bars, leather panels, paper-textured grids, photorealistic shadows on value marks, decorative screw heads, or effects that imply false mass/precision.
- If a real-world metaphor changes how a user estimates value, distance, uncertainty, scale, or selection, reject it.
- Every skeuomorphic cue must map to an operation: grab, press, focus, reset, constrain, select, warning, or disabled.

## Shader Policy

- Baseline assets must work with Godot `StandardMaterial3D` or simple unshaded shaders.
- Custom shaders require a named semantic purpose, a WebXR fallback, and reduced-motion/static fallback.
- Approved shader purposes: focus outline, hover halo, active manipulation pulse, invalid constraint stripe, selected edge, clipped/filtered ghosting, ray cursor state, label billboarding support.
- Disallowed baseline shader purposes: decorative noise, animated background shimmer, nonsemantic bloom, chromatic aberration, refraction on data marks, procedural texture that encodes no state.
- Quantitative colormaps should use unshaded or lighting-stable materials unless the encoded variable is explicitly material/lighting related.
- glTF PBR values must stay within theme budgets: base color tokenized, metallic low by default, roughness high by default, alpha minimized, emissive state-scoped.

## Theme Briefs

These are the pre-build briefs for the first pass. Blender assets should be reviewed against one of these before export.

### Theme Brief 1: Instrument Light

Purpose: default analytical workbench theme for desktop and general WebXR testing.

Look:

- Scientific Studio structure with Enterprise Instrument state discipline.
- White to very light neutral canvas; slightly cool gray structural chrome.
- Data marks are visually crisp and slightly saturated, but not glossy.
- Controls look manufactured and precise, with restrained tactile cues.

Aesthetic attributes:

| Attribute | Decision |
|---|---|
| Skeuomorphism | low-to-moderate for controls only; none for marks |
| Material model | matte PBR for controls/structure; unshaded or matte for data |
| Metallic | `0.0` baseline; maximum `0.1` for control accents |
| Roughness | `0.6-0.9` |
| Transparency | avoided except surfaces, selection volumes, tooltips |
| Shadows | off for marks/guides; optional soft contact/elevation only for panels in desktop |
| Emission | focus/ray only, low intensity |
| Geometry | crisp, exact, small bevels on controls; no bevels on value edges that affect reading |
| Shader use | focus outline, hover halo, active pulse with static fallback |
| WebXR fallback | same geometry family, lower detail, larger collision targets |

Component notes:

- `control/handle_linear`: capsule or faceted puck with grip groove; visible collision radius in validation; focus ring separate from body.
- `structure/axis_line`: thin rectangular/tubular line with non-color axis endcap option.
- `mark/bar`: square or subtly rounded box; baseline pivot must remain visually obvious.

### Theme Brief 2: Editorial Presentation

Purpose: demos, guided walkthroughs, screenshots, stakeholder review, and user studies.

Look:

- Calm explanatory chart language.
- Softer contrast, fewer grid elements, larger labels and annotation anchors.
- Emphasis through isolation and highlight color, not material effects.

Aesthetic attributes:

| Attribute | Decision |
|---|---|
| Skeuomorphism | minimal; only press/drag affordance on controls |
| Material model | flat matte, mostly unshaded |
| Metallic | `0.0` |
| Roughness | `0.8-1.0` if PBR is used |
| Transparency | panels may be lightly translucent only when text contrast is protected |
| Shadows | mostly none; use layout spacing and muted contrast |
| Emission | generally none except pointer visibility in headset |
| Geometry | simple silhouettes, generous label anchors, sparse guide variants |
| Shader use | reveal/fade/outline only; no glow or animated texture |
| WebXR fallback | larger labels, fewer grid lines, simple controls |

Component notes:

- `guide/tooltip_panel` and `guide/leader_line` are key aesthetic components.
- `control/button`: flat face, clear icon/label socket, obvious focus border.
- `mark/point`: sphere or disc with stable silhouette; avoid jewel-like highlight.

### Theme Brief 3: WebXR Dark Instrument

Purpose: headset operation in Quest/WebXR and dark immersive contexts.

Look:

- Dark neutral analytical space, not neon arcade.
- Larger interactive targets, high state clarity, low transparency, stable color.
- Depth hierarchy comes from position, outline, and reticle feedback rather than shadows.

Aesthetic attributes:

| Attribute | Decision |
|---|---|
| Skeuomorphism | moderate for controls where it improves grab/select discoverability |
| Material model | unshaded data; rough nonmetal PBR or unshaded controls |
| Metallic | `0.0` baseline |
| Roughness | `0.7-1.0` |
| Transparency | heavily restricted; alpha only for selection volumes/surfaces with fallback |
| Shadows | off by default |
| Emission | allowed for ray cursor, focus ring, active handle, warnings; budgeted and non-bloom dependent |
| Geometry | larger handles, thicker focus rings, simplified grid, interior label anchors |
| Shader use | unshaded reticles, outline, invalid-state stripe, reduced-motion pulse |
| WebXR fallback | primary, not secondary; every component must have low-poly form |

Component notes:

- `xr/ray_cursor`: unshaded reticle with shape change for valid/invalid/active.
- `control/handle_linear`: large enough for controller ray and direct grab, with non-color active cue.
- `structure/grid_line`: dim and sparse; avoid dense glowing cage effects.

## Proposed Labmarket Theme Set

### 1. Instrument Light

Primary default. Combines Scientific Studio precision with Enterprise Instrument discipline.

- Neutral light canvas, low-contrast guide lines, crisp dark labels.
- Data marks use a curated categorical sequence with accessible contrast.
- Controls use cyan/teal focus accents plus shape/outline cues.
- Bounds, axes, and handles are exact and minimal.
- Avoids glossy, neon, skeuomorphic, or game-like controls.

### 2. Editorial Presentation

For demos, studies, explanatory notebooks, and guided walkthroughs.

- Softer neutral canvas and larger label anchors.
- Fewer grid lines and stronger direct labels.
- Highlight color plus neutral comparison marks.
- Controls stay quiet unless focused or active.
- Best for screenshots, onboarding, and mixed-audience explanation.

### 3. WebXR Dark Instrument

For headset use and dark immersive rooms.

- Dark neutral background with unlit/lighting-stable data materials.
- Reduced transparency, no shadows, low triangle counts.
- Bigger handles, stronger focus rings, visible ray cursor states.
- Color is never the only state cue.
- Labels and guide anchors have near/interior viewing-distance variants.

## Attribute Checklist Before Building Any Asset

Each asset role brief should answer:

- Which lookbook theme owns the default appearance?
- Is the asset data-bearing, structure-bearing, control-bearing, or status-bearing?
- What is the exact pivot, forward axis, value axis, and physical size?
- What visual states are required?
- Which attributes are semantic and must be tokenized instead of baked?
- What non-color cue communicates hover, focus, selected, active, disabled, warning, or error?
- What is the WebXR low-cost variant?
- What collision/picking target does the user actually interact with?
- What can go wrong in stereo viewing, and how does the fallback stay usable?
