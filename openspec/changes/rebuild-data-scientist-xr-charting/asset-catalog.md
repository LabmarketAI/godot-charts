# Initial Spatial Asset Catalog

This catalog identifies visual roles, not a mandatory one-file-per-role implementation. Value-bearing geometry should remain procedural or batched where that improves accuracy and performance. Theme packs may replace any public role and inherit the rest.

Priority meanings:

- **P0**: required for the first coherent vertical slice and asset-authoring SDK.
- **P1**: required for the first broadly useful preview release.
- **P2**: valuable themed or advanced visualization coverage after the core system is stable.

## 1. Structural and orientation assets

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `structure/axis_line` | Positive/negative direction, optional arrow cap, scale-safe length |
| P0 | `structure/tick_major` | Exterior and interior-readable variants |
| P0 | `structure/tick_minor` | Lower emphasis than major tick |
| P0 | `structure/grid_line` | Solid/dashed material profiles; batched/procedural preferred |
| P0 | `structure/grid_plane` | XY, XZ, YZ; bounded transparency and fade |
| P0 | `structure/origin` | Non-color-only origin landmark |
| P0 | `structure/axis_endcap` | X/Y/Z differentiated without depending only on color |
| P0 | `structure/plot_bounds` | Frame/cage and floor-outline variants |
| P0 | `structure/reset_landmark` | Exterior/interior orientation and reset reference |
| P1 | `structure/reference_plane` | Zero, target, baseline, or comparison plane |
| P1 | `structure/reference_line` | Threshold, mean, target, cursor, or crosshair |
| P1 | `structure/scale_break` | Explicit discontinuity symbol |
| P1 | `structure/navigation_path` | Optional embodied path/breadcrumb through a plot |
| P2 | `structure/facet_separator` | Spatial small-multiple boundary |

## 2. Common data-mark assets

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `mark/point` | Sphere, disc/billboard, cube; batchable |
| P0 | `mark/line` | Thin line, tube, ribbon; procedural joins/caps |
| P0 | `mark/bar` | Square and subtly rounded; declared baseline/value axis |
| P0 | `mark/surface` | Lit and color-faithful unlit material profiles |
| P0 | `mark/area` | Plane/ribbon with bounded transparency |
| P0 | `mark/text` | Label anchor and leader socket, not embedded text |
| P1 | `mark/symbol` | Circle, square, triangle, diamond, cross, plus, star |
| P1 | `mark/vector` | Shaft plus arrowhead; magnitude/direction safe scaling |
| P1 | `mark/rule` | Segment, ray, span, error-bar stem |
| P1 | `mark/error_cap` | Symmetric/asymmetric uncertainty cap |
| P1 | `mark/error_band` | Ribbon/volume boundary and fill |
| P1 | `mark/voxel` | Dense volume-friendly cube with instancing |
| P1 | `mark/mesh` | Triangular mesh with edge-overlay option |
| P1 | `mark/contour` | Line and band variants |
| P1 | `mark/heat_cell` | Plane and shallow voxel variants |
| P2 | `mark/cone` | Vector-field cone |
| P2 | `mark/streamline` | Directional tube/ribbon with flow indication |
| P2 | `mark/isosurface` | Material profiles and clipping compatibility |
| P2 | `mark/density_cloud` | Point-sprite/voxel fallback families |

## 3. Guides, labels, legends, and inspection

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `guide/axis_label_anchor` | Billboard and world-anchored policies |
| P0 | `guide/tick_label_anchor` | Exterior/interior distance classes |
| P0 | `guide/title_anchor` | Title, subtitle, caption stack |
| P0 | `guide/legend_panel` | Flat, curved, docked, handheld-compatible |
| P0 | `guide/legend_swatch` | Symbol, color, line, gradient sockets |
| P0 | `guide/tooltip_panel` | Ray-safe panel with leader and pin state |
| P0 | `guide/leader_line` | Tooltip/annotation to mark |
| P0 | `guide/crosshair` | 2D and tri-planar 3D variants |
| P1 | `guide/color_ramp` | Sequential, diverging, cyclic |
| P1 | `guide/annotation_pin` | Note, warning, provenance, user annotation |
| P1 | `guide/measurement_ruler` | Data/world distance modes explicitly distinguished |
| P1 | `guide/selection_summary` | Count/range/status presentation |
| P2 | `guide/minimap` | Orientation and current-volume locator |

## 4. Interaction and analytical-control assets

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `control/handle_linear` | Axis endpoint, range endpoint, threshold; constrained drag |
| P0 | `control/axis_scrubber_rail` | Full analytical extent rail for axis viewport controls |
| P0 | `control/axis_scrubber_window` | Draggable visible-domain body; size communicates zoom level |
| P0 | `control/axis_scrubber_edge` | Min/max edge grip or handle for resizing the visible domain |
| P0 | `control/axis_scrubber_focus` | Optional zoom-focus marker for center, pointer, or selection focus |
| P0 | `control/slider_track` | Linear, stepped, range, time |
| P0 | `control/slider_thumb` | Ray and direct-touch hit targets |
| P0 | `control/button` | Icon/label socket; normal through disabled states |
| P0 | `control/grab_anchor` | Whole plot/view manipulation |
| P0 | `control/reset` | View, analytical, or full reset variants |
| P0 | `control/focus_ring` | Reusable non-color focus/selection outline |
| P0 | `control/hover_halo` | Restrained, performance-safe emphasis |
| P1 | `control/dial` | Cyclic and bounded parameter control |
| P1 | `control/axis_grip` | Domain zoom/pan and axis-specific state |
| P1 | `control/slice_plane` | Plane, edge handles, normal arrow, value label |
| P1 | `control/threshold_plane` | Visually distinct from slice and reference planes |
| P1 | `control/selection_box` | 2D brush extruded or planar |
| P1 | `control/selection_volume` | 3D box/sphere/lasso approximation and resize grips |
| P1 | `control/clip_box` | Clipping bounds and face/edge/corner handles |
| P1 | `control/playback` | Play, pause, step, speed, loop |
| P1 | `control/layer_toggle` | Visibility and isolate states |
| P1 | `control/undo_redo` | Analytical history, not application history |
| P1 | `control/constraint_feedback` | Min/max, invalid, snapped, locked cues |
| P2 | `control/two_hand_scale_anchor` | Discoverable two-hand plot scaling |
| P2 | `control/radial_menu` | Optional compact immersive tool chooser |

## 5. Interaction-state overlays

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `state/hover` | Outline/halo/label strategy |
| P0 | `state/focus` | Keyboard/ray focus distinct from hover |
| P0 | `state/selected` | Persistent redundant cue |
| P0 | `state/active` | Grab/drag/press state |
| P0 | `state/disabled` | Reduced affordance without becoming illegible |
| P0 | `state/filtered` | Hidden, ghosted, or contextual according to policy |
| P1 | `state/warning` | Constraint/data warning |
| P1 | `state/error` | Invalid asset/data/control state |
| P1 | `state/linked` | Counterpart in another view |
| P1 | `state/changed` | Streaming/revision update cue |
| P1 | `state/approximated` | Imported feature fidelity warning |

## 6. Quantum-circuit assets

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `circuit/wire_quantum` | Logical and physical-mapped style tokens |
| P0 | `circuit/wire_classical` | Visually distinct, accessible double/dashed form |
| P0 | `circuit/gate_standard` | Label socket; single-qubit baseline |
| P0 | `circuit/gate_opaque` | Custom/unsupported operation with diagnostic state |
| P0 | `circuit/control_closed` | Control identity socket |
| P0 | `circuit/control_open` | Negative/open control |
| P0 | `circuit/target` | Controlled-X/target symbol |
| P0 | `circuit/connector` | Quantum and classical variants |
| P0 | `circuit/measurement` | Qubit-to-classical destination connector |
| P0 | `circuit/barrier` | Directive semantics; non-gate visual |
| P0 | `circuit/layer_cursor` | Scrubbing and active causal context |
| P1 | `circuit/swap` | Paired swap symbols and connector |
| P1 | `circuit/condition` | Classical predicate badge/connector |
| P1 | `circuit/control_flow_region` | If/else, loop, switch grouping |
| P1 | `circuit/composite_group` | Expand/collapse bounds and disclosure handle |
| P1 | `circuit/parameter_handle` | Bound/unbound expression state |
| P1 | `circuit/dependency_highlight` | Predecessor/successor path |
| P1 | `circuit/layout_mapping` | Logical-to-physical qubit relationship |
| P1 | `circuit/comparison_link` | Pre/post-transpilation counterpart |
| P2 | `circuit/timing_span` | Only when schedule timing is supplied |

## 7. WebXR and fallback assets

| Priority | Semantic role | Initial variants / notes |
|---|---|---|
| P0 | `xr/ray_cursor` | Hover, valid, invalid, active states |
| P0 | `xr/direct_touch_cursor` | Poke/contact state where supported |
| P0 | `xr/grab_indicator` | Controller squeeze or hand-grab abstraction |
| P0 | `xr/teleport_or_entry_marker` | Plot entry point and comfort-safe destination |
| P0 | `fallback/minimal_point` | Procedural low-cost primitive |
| P0 | `fallback/minimal_line` | Procedural low-cost line |
| P0 | `fallback/minimal_bar` | Procedural low-cost box |
| P0 | `fallback/minimal_handle` | Guaranteed accessible control fallback |
| P1 | `xr/hand_affordance` | Pinch/grasp/poke hints, capability-gated |
| P1 | `xr/comfort_vignette` | Host-controlled and disabled by default |
| P1 | `fallback/billboard_label` | Low-cost label fallback |

## 8. Theme-pack contents

The initial official packs should share geometry when possible and primarily vary tokens/materials:

1. **Instrument Light (P0)** — warm-neutral surfaces, dark precise guides, controlled categorical chroma.
2. **Instrument Dark (P0)** — near-neutral dark field, restrained emission, lighting-stable data colors.
3. **High Contrast / Color-Vision Safe (P1)** — redundant symbols/outlines and stricter contrast.
4. **Presentation Gallery (P1)** — larger typography and marks for room-scale explanation, within semantic constraints.
5. **WebXR Performance (P0)** — minimal transparency, shared unlit materials, low-poly/control fallbacks, reduced motion.
6. **Quantum Lab (P1)** — circuit-focused tokens and gate family built on the same interaction language.

## 9. Authoring deliverables

- Blender starter file with metric units, canonical axes, sample pivots, sockets, collision proxies, LOD collections, material slots, and glTF export settings.
- Godot starter addon/project with manifest resource, preview gallery, token/material sockets, procedural-provider example, validation failures, and fallback demonstration.
- JSON or resource schema reference for asset packs and theme packs.
- Naming/versioning/migration guide for semantic roles.
- Performance-budget worksheet for desktop, native XR, and WebXR tiers.
- Licensing and provenance template for original and third-party assets.
