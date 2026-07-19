## 1. Method and Templates

- [ ] 1.1 Publish the role brief template covering role id, purpose, dimensions, pivot, axes, states, sockets, collision, LOD, budgets, fallback, and provenance.
- [x] 1.2 Create a Blender starter file with metric units, Godot orientation, collections, example pivots, semantic material slots, collision proxies, LOD examples, and GLB export settings.
  - Evidence: `tools/assets/blender/create_chart_asset_starter_scene.py` generates `tools/assets/blender/chart_asset_starter.blend` with metric units, `LOD0`/`LOD1`/`COLLISION`/`SOCKETS`/`PREVIEW`/`REFERENCES` collections, semantic materials, scale references, and an example `control/handle_linear` setup.
- [ ] 1.3 Create a ComfyUI support note for material/reference generation, including what may be imported and what cannot become baseline geometry without validation.
- [ ] 1.4 Document the object/material naming convention and GLB export checklist.
- [ ] 1.5 Convert the lookbook research into three theme briefs with token palettes, geometry rules, material rules, state rules, and WebXR constraints before authoring GLB assets.
- [ ] 1.6 Review the fundamental asset inventory and approve the P0/P1/P2 build order before Blender production begins.
- [ ] 1.7 Publish professional asset quality gates for smoothing, normals, bevels, topology, materials, shaders, export settings, validation, and artist handoff.
- [ ] 1.8 Publish a reusable Blender/3D asset prompting guide covering role, function, diegetic scale, interaction vocabulary, accessibility baseline, materials, polish, export, and negative constraints.

## 2. Manifest and Validator

- [ ] 2.1 Extend `asset_pack_manifest.json` or add a schema for GLB-backed role entries, LODs, sockets, dimensions, collision, budgets, and provenance.
- [ ] 2.2 Implement a Godot or scriptable validator for required roles, object names, pivots, bounds, material sockets, collision proxies, triangle/material counts, and WebXR tier limits.
- [ ] 2.3 Add deterministic fallback diagnostics when a role is missing, invalid, unsupported, or over budget.
- [ ] 2.4 Add packaging checks so official GLB packs and manifests are included while Blender source files remain authoring artifacts unless explicitly packaged.
- [ ] 2.5 Add validator checks for professional polish risks: missing normals/tangents, non-semantic material slots, over-budget alpha/shader use, missing collision proxies, concept objects in runtime exports, and absent fallback roles.

## 3. P0 Component Production

- [ ] 3.1 Author GLB-backed structural components for axis lines, ticks, grid lines, plot bounds, origin, and reset landmark.
- [ ] 3.2 Author GLB-backed common marks for point, bar, and line/tube roles while preserving batching semantics.
- [ ] 3.3 Author GLB-backed control components for linear handles, slider track/thumb, button, grab anchor, reset, focus ring, and hover halo.
- [ ] 3.4 Author the baseline WebXR ray cursor and ensure P0 fallback roles remain procedural and always available.
- [ ] 3.5 Record provenance, license, dimensions, budgets, and screenshots for each accepted component.

## 4. Godot Integration

- [ ] 4.1 Add a GLB asset-pack provider that resolves semantic roles through the manifest and falls back to the procedural factory.
- [ ] 4.2 Update the visual asset gallery to show procedural and GLB-backed variants side by side across states and WebXR tier.
- [ ] 4.3 Update chart frame/domain handles and at least one renderer to request assets through the provider rather than hard-coded meshes/materials.
- [ ] 4.4 Add headless tests for manifest loading, fallback behavior, role resolution, and renderer compatibility.
- [ ] 4.5 Add visual smoke evidence for desktop and WebXR template scenes.

## 5. Review and Acceptance

- [ ] 5.1 Validate every P0 role against pivot, bounds, socket, collision, LOD, budget, and fallback requirements.
- [ ] 5.2 Confirm controls are reachable and selectable in Quest/WebXR with ray/select and direct-grab paths where available.
- [ ] 5.3 Confirm structural assets do not distort perceived data values or obscure labels/marks.
- [ ] 5.4 Confirm the visual gallery and docs identify official, procedural, and fallback variants.
- [ ] 5.5 Publish acceptance evidence and update the broader rebuild asset catalog with completed roles.
