# Fundamental Chart Asset Inventory

This inventory defines the asset primitives needed to support the chart modes in the rebuild. It is intentionally more production-oriented than the broader asset catalog: these are the reusable building blocks that renderers, interactions, legends, and WebXR controls should request through semantic roles.

## Asset Layers

Assets are grouped by what they do in a chart:

- **Structure**: coordinate systems, frames, axes, grids, ticks, bounds, orientation.
- **Marks**: value-bearing geometry such as points, lines, bars, surfaces, areas, cells, vectors, and symbols.
- **Guides**: labels, legends, color ramps, crosshairs, annotations, tooltips, rulers.
- **Interaction**: handles, sliders, buttons, grips, brushes, selection volumes, cursors.
- **State**: hover, focus, selected, active, disabled, filtered, warning, error, linked, changed.
- **Fallback**: minimal procedural forms that keep charts usable without GLB packs.

## P0 Core Assets

P0 assets are required before the first production GLB pack can replace procedural visuals in the WebXR chart.

| Role | Asset | Used by | Notes |
|---|---|---|---|
| `structure/axis_line` | axis shaft | scatter, line, bar, surface, histogram, heatmap, circuit timeline | exact length scaling; optional axis endcap |
| `structure/axis_endcap` | directional axis cap | 3D coordinate views | shape cue per axis; not color-only |
| `structure/tick_major` | major tick mark | all axis-based charts | exterior/interior variants |
| `structure/tick_minor` | minor tick mark | dense scientific charts | lower emphasis than major ticks |
| `structure/grid_line` | grid segment | scatter, line, bar, surface, heatmap | batchable, low contrast |
| `structure/grid_plane` | coordinate plane | surface, heatmap, slice/threshold views | bounded alpha, WebXR fallback |
| `structure/plot_bounds` | frame/cage/bounds | all spatial chart frames | exact extents; not decorative |
| `structure/origin` | origin landmark | 3D coordinate views | redundant non-color cue |
| `structure/reset_landmark` | reset/orientation marker | frame controls, WebXR | reachable, recognizable, non-value-bearing |
| `mark/point` | point glyph | scatter, bubble, swarm, sampled lines, geospatial points | sphere/disc/cube variants; MultiMesh-friendly |
| `mark/line` | line segment/tube | line, path, edge, contour, circuit wire | thin line and tube variants |
| `mark/bar` | bar/column | bar, histogram, waterfall, categorical comparisons | baseline-center pivot; value axis declared |
| `mark/surface` | surface patch | 3D surface, terrain-like scientific surfaces | unlit quantitative color path |
| `mark/area` | area/ribbon fill | area, confidence bands, stacked areas | bounded transparency |
| `mark/text_anchor` | label anchor/socket | labels, legends, annotations | anchor only; text rendered by Godot label system |
| `guide/axis_label_anchor` | axis label anchor | all axis charts | exterior/interior placement |
| `guide/tick_label_anchor` | tick label anchor | all axis charts | deterministic orientation |
| `guide/title_anchor` | title/subtitle anchor | figures and frames | title/caption stack |
| `guide/legend_panel` | legend container | categorical, size, color, shape legends | panel variants for flat/spatial use |
| `guide/legend_swatch` | legend swatch socket | all legends | point/line/bar/color-ramp sockets |
| `guide/tooltip_panel` | tooltip/inspection panel | inspection workflows | ray-safe, readable, optional pin |
| `guide/leader_line` | leader/callout line | annotations, tooltips | unobtrusive, target identity preserved |
| `guide/crosshair` | cursor/crosshair | inspection, measurement, brushing | 2D and tri-planar variants |
| `control/handle_linear` | linear/domain handle | axis domain, threshold, range endpoints | controller-ray and direct-grab target |
| `control/axis_scrubber_rail` | axis viewport rail | axis pan/zoom scrubbers | represents full extent; exact scalable length |
| `control/axis_scrubber_window` | visible viewport body | axis pan/zoom scrubbers | draggable body; size and position encode visible domain |
| `control/axis_scrubber_edge` | viewport edge grip/handle | axis pan/zoom scrubbers | min/max edge resize; large ray target |
| `control/axis_scrubber_focus` | viewport zoom focus marker | axis pan/zoom scrubbers | optional pointer/center/selection focus cue |
| `control/slider_track` | slider/range track | filters, time, thresholds | stepped/range-ready |
| `control/slider_thumb` | slider thumb | filters, time, thresholds | large WebXR hit target |
| `control/button` | button body/socket | reset, mode, confirm/cancel | icon/label socket; stateful |
| `control/grab_anchor` | frame/view grab handle | move/rotate/resize frame | separate from chart-content handles |
| `control/reset` | reset control | view/domain/frame reset | explicit scope through icon/label socket |
| `control/focus_ring` | focus outline | all interactive assets | non-color focus cue |
| `control/hover_halo` | hover emphasis | marks and controls | restrained, low cost |
| `xr/ray_cursor` | ray cursor/reticle | WebXR pointer selection | valid/invalid/active states |
| `fallback/minimal_point` | procedural point | all point fallbacks | always available |
| `fallback/minimal_line` | procedural line | axes, grids, lines | always available |
| `fallback/minimal_bar` | procedural box | bars, histograms | always available |
| `fallback/minimal_handle` | procedural handle | all controls | always selectable |

## P1 Analytical Assets

P1 assets unlock richer chart families and analytical controls after the core pack works.

| Role | Asset | Used by | Notes |
|---|---|---|---|
| `mark/symbol_circle` | circle symbol | categorical scatter, legends | shape-coded category |
| `mark/symbol_square` | square symbol | categorical scatter, legends | shape-coded category |
| `mark/symbol_triangle` | triangle symbol | categorical scatter, legends | orientation stable |
| `mark/symbol_diamond` | diamond symbol | categorical scatter, legends | shape-coded category |
| `mark/symbol_cross` | cross symbol | categorical scatter, diagnostics | high contrast |
| `mark/vector` | vector shaft/head | vector fields, arrows, flow, deltas | magnitude-safe scaling |
| `mark/rule` | rule/span segment | reference lines, error bars | exact endpoints |
| `mark/error_cap` | uncertainty cap | error bars, intervals | symmetric/asymmetric |
| `mark/error_band` | uncertainty band | confidence intervals, ribbons | alpha constrained |
| `mark/heat_cell` | heatmap cell | heatmap, matrix, table heat overlays | planar and shallow-voxel variants |
| `mark/voxel` | voxel/cell cube | volume grids, binned 3D histograms | instancing-friendly |
| `mark/mesh` | triangulated mesh | surfaces, finite-element style plots | edge overlay option |
| `mark/contour` | contour line/band | contour, isolines | line and band variants |
| `guide/color_ramp` | color ramp legend | heatmap, surface, continuous color | sequential/diverging/cyclic |
| `guide/annotation_pin` | annotation marker | notes, provenance, warnings | author/status socket |
| `guide/measurement_ruler` | ruler/measurement | spatial measurement | data/world units explicit |
| `guide/selection_summary` | selection summary panel | brushing, linked selections | count/range/status |
| `control/axis_grip` | axis grip | axis selection and mode controls | axis-specific affordance distinct from viewport scrubbers |
| `control/slice_plane` | slice plane | volume, surface, tensor views | plane + edge handles |
| `control/threshold_plane` | threshold plane | filtering, segmentation | visually distinct from reference plane |
| `control/selection_box` | 2D brush box | scatter, heatmap, bar ranges | planar/extruded variants |
| `control/selection_volume` | 3D selection volume | 3D scatter, volume | box/sphere/lasso approximation |
| `control/clip_box` | clipping bounds | dense 3D views | face/edge/corner handles |
| `control/playback` | playback controls | time, animation, simulation | play/pause/step/speed |
| `control/layer_toggle` | layer visibility control | multi-layer charts | isolate/visibility states |
| `control/constraint_feedback` | constraint cue | invalid/snap/limit feedback | warning/error state shapes |

## P2 Specialized Assets

P2 assets are specialized and should wait until core chart modes and interaction validation are stable.

| Role | Asset | Used by | Notes |
|---|---|---|---|
| `mark/cone` | vector cone | vector fields | optional high-density fallback |
| `mark/streamline` | streamline tube/ribbon | flow fields | direction cue required |
| `mark/isosurface` | isosurface shell | volume/scientific fields | performance-gated |
| `mark/density_cloud` | density cloud | large scatter/point clouds | LOD/fallback required |
| `structure/facet_separator` | facet divider | small multiples | spatial layout support |
| `structure/navigation_path` | embodied path | immersive chart navigation | comfort-reviewed |
| `guide/minimap` | minimap/orientation | large spatial plots | optional |
| `control/dial` | dial/knob | cyclic parameters | avoid accidental manipulation |
| `control/two_hand_scale_anchor` | two-hand scale anchor | native XR/hand tracking | not WebXR baseline |
| `control/radial_menu` | radial menu | immersive tools | optional compact commands |

## Chart Mode Coverage

| Chart mode | Required assets |
|---|---|
| Scatter / bubble | point, symbol variants, axes, ticks, grid, bounds, tooltip, crosshair, selection box/volume |
| Line / path | line, point, axes, ticks, grid, tooltip, legend swatch, crosshair |
| Bar / column | bar, axes, ticks, grid, baseline, labels, legend swatch |
| Histogram | bar, axes, ticks, grid, bin labels, tooltip |
| Area / ribbon | area, line, axes, ticks, grid, alpha-safe material, legend swatch |
| Surface | surface, mesh, axes, grid planes, color ramp, tooltip, slice/threshold controls |
| Heatmap / matrix | heat cell, axes, tick labels, color ramp, tooltip, selection box |
| Contour | contour, color ramp, axes, grid, tooltip |
| Vector field | vector, cone optional, axes, grid, color/size legend |
| Volume / voxel | voxel, selection volume, clip box, slice plane, color ramp, WebXR LOD |
| Network / graph | point/node, line/edge, arrow head, labels, tooltip, selection/link state |
| Geospatial local view | point, line/path, polygon/area, tile/terrain optional, north/scale guides, attribution panel |
| Quantum circuit | wires, gates, controls, targets, measurement, barrier, layer cursor, parameter handles |
| Compound figure | frame bounds, facet separators, title anchors, legend panels, linked-state overlays |

## Cross-Cutting Requirements

Every fundamental asset must declare:

- stable role id
- category
- pivot
- forward/up axis
- value axis where applicable
- dimensions and scalable axes
- material sockets
- supported states
- collision/picking proxy
- LOD variants
- batching compatibility
- WebXR budget
- procedural fallback
- license/provenance

## Build Order

1. P0 structure and fallback line primitives.
2. P0 controls: linear handle, axis scrubber rail/window/edge/focus, focus ring, hover halo, ray cursor.
3. P0 marks: point, bar, line.
4. P0 guide anchors and tooltip/legend basics.
5. P1 analytical controls: axis grip, selection box/volume, slice plane.
6. P1 richer marks: symbols, vectors, heat cells, error marks.
7. P2 specialized chart-family assets.
