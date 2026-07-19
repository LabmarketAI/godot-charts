# Chart Asset Production Method

## Roles

- **Blender MCP**: canonical geometry authoring and inspection for official GLB packs.
- **Godot typed GDScript**: semantic role registry, fallback primitives, asset-pack loading, validation, gallery rendering, and renderer consumption.
- **ComfyUI**: optional concept/material/texture helper. Outputs are references or imported material inputs until they pass Blender/Godot validation.

## Workflow

1. **Role brief**
   - Choose a semantic role from the asset catalog or add a proposed role.
   - Record category, analytical purpose, required states, viewing-distance class, WebXR tier, dimensions, pivot, forward/up axis, material sockets, collision/picking bounds, batching mode, and fallback.

2. **Blender authoring**
   - Work in metric units with Godot-compatible orientation and scale.
   - Name objects with stable prefixes: `role__`, `lod__`, `socket__`, `collision__`, `origin__`, `preview__`.
   - Keep value-bearing geometry visually neutral and scale-safe.
   - Use separate collections for `LOD0`, `LOD1`, `COLLISION`, `SOCKETS`, and `PREVIEW`.
   - Set origins/pivots exactly; do not rely on importer offsets.

3. **Material and socket discipline**
   - Use semantic material slot names such as `data_color`, `guide`, `outline`, `focus`, `selection`, `warning`, `disabled`, `label_anchor`, and `collision_hidden`.
   - Do not bake data values, theme colors, labels, or interaction state into geometry.
   - Texture inputs from ComfyUI must be source-controlled only if license/provenance and WebXR budgets are recorded.

4. **GLB export**
   - Export only selected role collections.
   - Preserve object names, transforms, custom properties where available, and material slots.
   - Exclude cameras, lights, decorative environment geometry, and hidden concept objects from runtime GLBs.

5. **Godot validation**
   - Validate the manifest, roles, object naming, pivots, dimensions, material sockets, collision shapes, triangle/material counts, scale, forward/up axes, LODs, license/provenance, and WebXR compatibility.
   - Import failures must fall back deterministically to procedural assets with diagnostics.

6. **Gallery and renderer adoption**
   - Add each accepted role to the visual asset gallery across normal, hover, focus, selected, active, disabled, warning, and error states where applicable.
   - Adopt GLB assets in renderers through role requests, not direct file paths.
   - Keep procedural fallback fixtures passing for every GLB-backed role.

## First Component Set

P0 official asset roles for the first production pass:

- `structure/axis_line`
- `structure/tick_major`
- `structure/grid_line`
- `structure/plot_bounds`
- `structure/origin`
- `structure/reset_landmark`
- `mark/point`
- `mark/bar`
- `mark/line`
- `control/handle_linear`
- `control/slider_track`
- `control/slider_thumb`
- `control/button`
- `control/grab_anchor`
- `control/reset`
- `control/focus_ring`
- `control/hover_halo`
- `xr/ray_cursor`
- `fallback/minimal_point`
- `fallback/minimal_line`
- `fallback/minimal_bar`
- `fallback/minimal_handle`

P1 follow-up roles:

- `guide/legend_panel`
- `guide/legend_swatch`
- `guide/tooltip_panel`
- `guide/leader_line`
- `control/axis_grip`
- `control/slice_plane`
- `control/selection_box`
- `control/selection_volume`
- `mark/vector`
- `mark/error_cap`
- `mark/error_band`

## Budget Defaults

- WebXR P0 controls: one material socket group per state family, no shadows, no required transparency, collision target at least 12 cm equivalent at interaction distance.
- WebXR P0 marks: batchable or instanced; GLB detail must not prevent MultiMesh/procedural fallback.
- Structural guides: low contrast, thin geometry, no decorative bevels that shift perceived values.
- Handles/buttons: redundant shape and outline states; color alone is insufficient.
