# P0 Prompt: `mark/line`

```text
Create mark/line: a line/tube segment asset for line charts, paths, graph edges, contours, and circuit wires.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: renderer-scaled segment between data points in frames viewed from 1.0-2.0 m.
- Visible body dimensions: normalized length 1.0 m, radius/thickness 0.006-0.014 m depending theme and data density.
- Collision/picking proxy: renderer/provider may add wider picking capsule for inspection.
- Interaction distance: readable in desktop and headset views.

Theme:
- Target lookbook: Instrument Light with WebXR Dark Instrument variant.
- Mood: crisp, continuous, scientific, not decorative.
- Avoid: glowing rope, cable, pipe, rough faceted cylinder.

Shape:
- Silhouette: straight smooth tube or flat ribbon/line variant with exact endpoints.
- Required geometry: segment body, optional cap style.
- Symmetry/origin: centered at local origin, length along local X unless provider remaps.
- Value-bearing edges/surfaces that must remain exact: endpoints and centerline.

Interaction vocabulary:
- Supported states: normal, hover, selected, filtered, disabled, warning.
- Input modes: ray/pointer inspection through renderer picking.
- Required cues: selected can use outline/halo/thickness change in addition to color.
- Cancellation/release behavior: not applicable.

Materials and shaders:
- Semantic material slots: data_matte, data_selected_outline, data_filtered, status_warning.
- Material model: unshaded or matte PBR.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, high roughness, opaque baseline.
- Shader constraints: no glow unless specifically used as focus overlay; no lighting-dependent quantitative color.

Professional polish:
- Shade smooth: tube variant.
- Keep sharp: ribbon/flat variant edges if used.
- Bevel radius/segments: tube profile should be smooth enough for target distance.
- Weighted/custom normals: optional for flat/ribbon variant.
- Topology constraints: no visible tube faceting, exact normalized endpoints, no cap artifacts.

Accessibility:
- Contrast target: selected/hover line state reaches 3:1 where meaningful.
- Non-color cues: thickness/outline/halo available.
- Target size/collision: renderer-level picking tolerance wider than visual line for thin marks.
- Metadata: series/path/row identity supplied by renderer/provider.
- Reduced-motion/alternate input: no required animation.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__mark_line, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked labels.
- Procedural fallback role: fallback/minimal_line.

Negative constraints:
- No glowing rope, no cable texture, no rough faceted cylinder, no baked labels, no background scene.
```
