# Professional Asset Quality Gates

These gates define how we prevent chart assets from looking temporary, blocky, or low-effort before handing briefs to an artist or accepting generated/Blender-authored assets. The goal is not to make every asset high-poly. The goal is clean silhouette, intentional normals, disciplined materials, reliable interaction geometry, and renderer-safe polish.

## Sources Reviewed

- Blender Shade Smooth changes face smoothing/normals and can make surfaces appear smooth without changing geometry; Auto Smooth keeps sharp and smooth areas separated by angle: https://docs.blender.org/manual/ru/3.4/scene_layout/object/editing/shading.html
- Blender Bevel Modifier provides non-destructive edge rounding, hardened normals, and face-strength settings; it can pair with weighted normals for clean hard-surface results: https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/bevel.html
- Blender Weighted Normal Modifier changes custom normals and can preserve flat-looking large faces while improving shading on bevels and small faces: https://docs.blender.org/manual/ca/4.3/modeling/modifiers/normals/weighted_normal.html
- Blender glTF exporter supports material export, normals, tangents, UVs, vertex colors, and unlit materials through `KHR_materials_unlit`: https://docs.blender.org/manual/en/3.3/addons/import_export/scene_gltf2.html
- glTF 2.0 PBR uses a portable metallic-roughness material model with base color, metallic, roughness, alpha, normal, occlusion, and emissive properties: https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html and https://www.khronos.org/gltf/pbr
- Godot shaders support unshaded rendering modes where lighting-stable appearance is required: https://docs.godotengine.org/en/stable/tutorials/shaders/introduction_to_shaders.html

## Professional Polish Criteria

An official asset must pass all applicable criteria before integration:

| Gate | Required Standard |
|---|---|
| Silhouette | No accidental faceting at expected viewing distances; curves are smooth enough for desktop and headset review |
| Normals | Smooth/flat shading is intentional; no muddy averaged normals across hard edges |
| Bevels | Exposed hard edges on controls/panels get small bevels unless exact analytical value edges require crisp geometry |
| Weighted normals | Hard-surface assets use weighted/custom normals where needed to keep broad faces clean and bevels polished |
| Topology | No nonmanifold runtime mesh, z-fighting, duplicate coincident faces, accidental internal faces, or unmerged seams visible in review |
| Pivots | Origin/pivot is exact and documented; no visual offset from interaction anchor |
| Scale | Physical size matches role brief and is readable/reachable in WebXR |
| Materials | Materials are tokenized, named semantically, and within theme budgets |
| Shaders | Any custom shader has a semantic purpose, fallback, and WebXR/reduced-motion path |
| Textures | Textures are licensed, power-of-two where useful, compressed/importable, and not required for state semantics |
| Interaction | Collision/picking proxy is larger than decorative mesh where needed and visible in validation preview |
| LOD | WebXR LOD is not just decimated damage; it keeps silhouette and interaction target clear |
| Export | GLB includes normals/tangents/material slots where needed and excludes authoring cameras/lights/concepts |
| Gallery | Asset appears professional in visual gallery under normal, hover, focus, active, disabled, warning/error where applicable |

## Blender Authoring Rules

### Shading and Normals

- Use `Shade Smooth` for curved surfaces and rounded controls where faceted polygons would look temporary.
- Use Auto Smooth / sharp edges / split normals where an asset has both curved and flat regions.
- Use Weighted Normal on hard-surface controls, buttons, handles, panels, bars, and bounds where bevels should look polished while broad faces stay visually flat.
- Do not use blanket smooth shading on exact analytical geometry if it makes flat value surfaces look warped.
- Mark hard edges intentionally. A large bar face should read as flat; its control-like edge may be subtly beveled.

### Bevels

- Use small real geometry bevels for interactive controls, panels, buttons, handles, and exposed non-value edges.
- Prefer Bevel Modifier with hardened normals for authoring so artists can tune radius/segments non-destructively.
- Bevels should be large enough to catch light/focus in the target theme but not so large that they change the perceived value, endpoint, or baseline.
- Avoid beveling value-bearing boundaries where rounding implies false uncertainty or changes the measurement edge.

### Topology

- Use enough segments for circles/capsules/spheres to look polished at expected headset distance.
- Avoid needless high density: professionalism comes from normals, bevels, and silhouette control, not raw polygon count.
- Remove hidden concept geometry from runtime exports.
- Keep collision proxies separate and simple; do not use dense render mesh as the only interactive collider.

### Materials

- Use semantic material slot names: `data_matte`, `structure_quiet`, `control_body`, `control_focus`, `control_active`, `status_warning`, `status_error`, `collision_hidden`.
- Use low-metal, high-roughness PBR for most control bodies and structure.
- Use unshaded or lighting-stable material paths for value-bearing data color.
- Avoid accidental glossy plastic, chrome, glass, or toy-like material unless the theme brief explicitly calls for it.

## Automated / Scriptable Checks

The validator should fail or warn on:

- missing manifest role entry
- missing pivot/origin metadata
- mesh bounds outside role dimensions
- missing collision proxy for interactive roles
- missing material sockets required by role metadata
- material names not in semantic allowlist
- too many materials per role or per WebXR LOD
- missing normals on GLB export
- missing tangents when normal maps are used
- alpha/blend material used in WebXR P0 role without fallback
- triangle count over budget
- object names outside allowed prefixes
- cameras/lights/concept collections included in runtime GLB
- no procedural fallback for chart-critical role

Some professional qualities still require visual review:

- silhouette polish
- bad smoothing artifacts
- bevel radius appropriateness
- material taste and theme fit
- label/control legibility in stereo
- whether an asset feels toy-like, temporary, or decorative

## Review Views

Each accepted asset should be reviewed in:

- Blender material preview
- Blender flat-lit viewport to expose silhouette/faceting
- Godot desktop gallery in light theme
- Godot desktop gallery in dark theme
- WebXR dark instrument gallery
- close headset distance for controls
- far/interior headset distance for structure and marks

## Artist Handoff Requirements

Every artist-facing asset brief must include:

- role id and chart modes supported
- theme brief target
- physical dimensions and pivot
- exact value-bearing edges that must not be rounded
- surfaces that should use shade smooth
- edges that should remain sharp
- bevel radius range and segment target
- material slot list
- shader constraints
- collision proxy shape and minimum target size
- LOD budgets
- screenshots of accepted/reference examples
- examples of rejected low-poly/temp-looking outcomes

## Definition of Done

An asset is production-ready when:

- it passes manifest and GLB validation
- it has intentional smooth/flat shading and no visible unintended faceting
- hard-surface polish is achieved through bevels and weighted normals where applicable
- value-bearing surfaces remain analytically honest
- it looks coherent in all three theme briefs or has documented theme-specific variants
- WebXR fallback is clear, selectable, and not visibly broken
- procedural fallback remains available
