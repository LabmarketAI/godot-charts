## 1. Method and Templates

- [ ] 1.1 Publish the role brief template covering role id, purpose, dimensions, pivot, axes, states, sockets, collision, LOD, budgets, fallback, and provenance.
- [x] 1.2 Create a Blender starter file with metric units, Godot orientation, collections, example pivots, semantic material slots, collision proxies, LOD examples, and GLB export settings.
  - Evidence: `tools/assets/blender/create_chart_asset_starter_scene.py` generates `tools/assets/blender/chart_asset_starter.blend` with metric units, `LOD0`/`LOD1`/`COLLISION`/`SOCKETS`/`PREVIEW`/`REFERENCES` collections, semantic materials, scale references, and an example `control/handle_linear` setup.
- [ ] 1.3 Create a ComfyUI support note for material/reference generation, including what may be imported and what cannot become baseline geometry without validation.
- [ ] 1.4 Document the object/material naming convention and GLB export checklist.
- [ ] 1.5 Convert the lookbook research into three theme briefs with token palettes, geometry rules, material rules, state rules, and WebXR constraints before authoring GLB assets.
- [ ] 1.6 Review the fundamental asset inventory and approve the P0/P1/P2 build order before Blender production begins.
- [ ] 1.7 Publish professional asset quality gates for smoothing, normals, bevels, topology, materials, shaders, export settings, validation, and artist handoff.
- [x] 1.8 Publish a reusable Blender/3D asset prompting guide covering role, function, diegetic scale, interaction vocabulary, accessibility baseline, materials, polish, export, and negative constraints.
  - Evidence: `asset-prompting-guide.md`, `prompts/templates/blender-asset-prompt.md`, and `prompts/p0/control-handle-linear.md` now include reusable prompt structure, diegetic scale, interaction vocabulary, accessibility, polish, export constraints, and the promoted icon/state-overlay rule that prevents stacked visible overlays.

## 2. Manifest and Validator

- [x] 2.1 Extend `asset_pack_manifest.json` or add a schema for GLB-backed role entries, LODs, sockets, dimensions, collision, budgets, and provenance.
  - Evidence: `addons/godot-charts/assets/visual/glb/asset_pack_manifest.json` defines the GLB pack schema and `control/handle_linear` role with source prompt/blend provenance, pivot/axis metadata, dimensions, LODs, sockets, collision, inputs, accessibility, material slots, tier-to-LOD mapping, and fallback role.
- [x] 2.2 Implement a Godot or scriptable validator for required roles, object names, pivots, bounds, material sockets, collision proxies, triangle/material counts, and WebXR tier limits.
  - Evidence: `tools/assets/validate_glb_asset_pack.py` validates the manifest and GLB JSON chunk for role entries, asset paths, LOD mesh nodes, sockets, collision proxies, duplicate nodes, semantic materials, normals, triangle counts, shadow-free tier budgets, and the `control/handle_linear` two-stroke axis cue rule.
- [x] 2.3 Add deterministic fallback diagnostics when a role is missing, invalid, unsupported, or over budget.
  - Evidence: `glb_visual_asset_provider.gd` reports structured diagnostics for missing roles, invalid role entries, missing/invalid performance tiers, unsupported tiers, and GLB load failures before falling back to procedural assets; `test_visual_assets.gd` asserts missing-role and unsupported-tier diagnostics.
- [x] 2.4 Add packaging checks so official GLB packs and manifests are included while Blender source files remain authoring artifacts unless explicitly packaged.
  - Evidence: `scripts/test-visual-assets.sh` now checks that the built addon contains the GLB manifest and `control_handle_linear.glb`, rejects packaged `.blend`/`.blend1` authoring files, and verifies Godot creates an import cache for the GLB before provider tests run.
- [x] 2.5 Add validator checks for professional polish risks: missing normals/tangents, non-semantic material slots, over-budget alpha/shader use, missing collision proxies, concept objects in runtime exports, and absent fallback roles.
  - Evidence: `tools/assets/validate_glb_asset_pack.py` rejects missing normals, undeclared material slots, non-collision alpha, missing collision proxies, missing fallbacks, non-runtime concept/reference/preview nodes, visible stacked state overlays, and WebXR tier budget violations.

## 3. P0 Component Production

- [ ] 3.1 Author GLB-backed structural components for axis lines, ticks, grid lines, plot bounds, origin, and reset landmark.
- [ ] 3.2 Author GLB-backed common marks for point, bar, and line/tube roles while preserving batching semantics.
- [ ] 3.3 Author GLB-backed control components for linear handles, slider track/thumb, button, grab anchor, reset, focus ring, and hover halo.
  - Progress: first `control/handle_linear` GLB generated from `tools/assets/blender/create_control_handle_linear_asset.py`, with source blend at `tools/assets/blender/generated/control_handle_linear.blend`, runtime GLB at `addons/godot-charts/assets/visual/glb/control_handle_linear.glb`, and manifest entry in `addons/godot-charts/assets/visual/glb/asset_pack_manifest.json`.
- [ ] 3.4 Author the baseline WebXR ray cursor and ensure P0 fallback roles remain procedural and always available.
- [ ] 3.5 Record provenance, license, dimensions, budgets, and screenshots for each accepted component.

## 4. Godot Integration

- [x] 4.1 Add a GLB asset-pack provider that resolves semantic roles through the manifest and falls back to the procedural factory.
  - Evidence: `glb_visual_asset_provider.gd` resolves roles from `glb/asset_pack_manifest.json`, annotates instantiated GLB nodes with provider/source metadata, reports structured diagnostics, and falls back to `ProceduralVisualAssetFactory`; `tests/visual/godot/test_visual_assets.gd` covers manifest loading, `control/handle_linear` resolution, and missing-role fallback.
- [x] 4.2 Update the visual asset gallery to show procedural and GLB-backed variants side by side across states and WebXR tier.
  - Progress: demo scene now uses a hybrid GLB path for `control/handle_linear`: `demo/scenes/main.tscn` instances `control_handle_linear.glb` as an editor-visible child while `gdscript_demo_main.gd` keeps runtime loading/fallback behavior for the same asset role.
  - Evidence: `visual_asset_gallery_3d.gd` now creates a procedural variant for every registered role and GLB variants for manifest-backed roles; `gallery_snapshot()` reports procedural and GLB counts, and `test_visual_assets.gd` asserts both paths.
- [x] 4.3 Update chart frame/domain handles and at least one renderer to request assets through the provider rather than hard-coded meshes/materials.
  - Evidence: `AnalyticalFrame3D` now owns six semantic axis-domain handles under `HandleRoot`, instantiates them through `GlbVisualAssetProvider` with WebXR tier options, positions them from the active frame bounds, and annotates channel/edge/interaction metadata for controller integration.
- [x] 4.4 Add headless tests for manifest loading, fallback behavior, role resolution, and renderer compatibility.
  - Evidence: `scripts/test-visual-assets.sh` covers manifest loading, GLB role resolution, fallback behavior, fallback diagnostics, gallery variants, packaging, runtime collision proxies, and Godot GLB import cache creation. `scripts/test-m2-foundation.sh` now validates the GLB pack, imports the GLB probe, and `test_m2_frame_state.gd` asserts `AnalyticalFrame3D` exposes six GLB-backed domain handles, resolves picked collision proxies back to semantic handles, and starts axis-domain preview from a picked handle while preserving frame lifecycle behavior.
- [ ] 4.5 Add visual smoke evidence for desktop and WebXR template scenes.
  - Progress: WebXR template packaging now rebuilds the current M1 addon into the temporary headset project, validates the GLB asset pack, performs a deterministic Godot import, and fails if `control_handle_linear.glb` does not produce an import cache. Local WebXR export evidence remains blocked until Godot 4.7 web export templates are available under the configured export data home.
  - Progress: the WebXR template now has a shared chart inspection base scene at `game/chart_inspection/chart_inspection_root.tscn`, with separate desktop/editor and VR entry scenes. The headset entry uses the same chart root as the desktop inspection scene instead of rebuilding the chart through the older template zone path.

## 5. Review and Acceptance

- [ ] 5.1 Validate every P0 role against pivot, bounds, socket, collision, LOD, budget, and fallback requirements.
- [ ] 5.2 Confirm controls are reachable and selectable in Quest/WebXR with ray/select and direct-grab paths where available.
  - Progress: GLB-backed `control/handle_linear` instances now receive manifest-derived `StaticBody3D` collision proxies; `AnalyticalFrame3D.resolve_domain_handle()` maps picked child/collider targets back to channel/edge metadata, and `AxisDomainInteractionController.begin_from_handle()` starts domain previews from picked handles. Quest/WebXR device confirmation remains open.
  - Progress: the WebXR template chart now uses the GLB-backed `control/handle_linear` asset for axis-domain handles, adds larger pointable targets and visible `X/Y/Z min/max` labels, and logs `chart-domain-status`, `chart-domain-preview`, and `chart-domain-commit` messages for trigger-ray and grip-drag attempts. This should replace the old procedural handle in headset builds and make failed right-controller grabs observable in the host log.
  - Progress: `zone_base.tscn` now lets both left and right XR Tools ranged pickup functions collide with layer 19 grab handles, not just layer 3 pickable objects, so grip-based ranged selection can acquire chart handles.
  - Progress: `game/main.tscn` now loads `game/chart_inspection/chart_inspection_vr.tscn` directly and enables XR Tools passthrough by default. The default VR inspection scene omits the separate frame move/rotate handles, leaving the six labeled axis-domain handles as the initial interaction surface.
- [ ] 5.3 Confirm structural assets do not distort perceived data values or obscure labels/marks.
- [ ] 5.4 Confirm the visual gallery and docs identify official, procedural, and fallback variants.
- [ ] 5.5 Publish acceptance evidence and update the broader rebuild asset catalog with completed roles.
