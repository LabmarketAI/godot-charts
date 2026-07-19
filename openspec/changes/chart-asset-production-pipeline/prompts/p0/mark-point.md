# P0 Prompt: `mark/point`

```text
Create mark/point: a professional point glyph for scatter, bubble, and sampled data marks.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: instanced point marks in chart frames viewed from 1.0-2.0 m.
- Visible body dimensions: normalized diameter 0.04 m, scalable by renderer for data size encoding.
- Collision/picking proxy: renderer/provider may use larger primitive picking proxy; mesh itself is value mark.
- Interaction distance: readable in dense and sparse scatter views.

Theme:
- Target lookbook: Instrument Light and WebXR Dark Instrument.
- Mood: clean, scientific, stable silhouette, not decorative.
- Avoid: glass marble, chrome bead, toy ball, faceted low-poly gem.

Shape:
- Silhouette: sphere and optional disc/cube variants; default sphere must be smooth.
- Required geometry: centered glyph with clean material slot.
- Symmetry/origin: centered at local origin.
- Value-bearing edges/surfaces that must remain exact: center position; size is renderer-controlled.

Interaction vocabulary:
- Supported states: normal, hover, selected, filtered, disabled.
- Input modes: ray/pointer inspection through renderer picking, not direct grab by default.
- Required cues: selected state can use outline/halo/size in addition to color.
- Cancellation/release behavior: not applicable.

Materials and shaders:
- Semantic material slots: data_matte, data_selected_outline, data_filtered.
- Material model: unshaded or lighting-stable matte.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, roughness 0.8-1.0 if PBR, opaque baseline.
- Shader constraints: no lighting-dependent quantitative color; selected outline/halo allowed via separate state asset.

Professional polish:
- Shade smooth: sphere variant.
- Keep sharp: cube variant only.
- Bevel radius/segments: cube variant may use tiny bevel if not value-distorting.
- Weighted/custom normals: cube variant if beveled.
- Topology constraints: no visible sphere faceting at intended viewing distance; MultiMesh-friendly.

Accessibility:
- Contrast target: selected/hover outlines support 3:1 non-text contrast where state is meaningful.
- Non-color cues: outline/halo/size/symbol variant available.
- Target size/collision: dense marks can use renderer-level picking tolerance.
- Metadata: row/series/value identity supplied by renderer/provider.
- Reduced-motion/alternate input: no required animation.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__mark_point, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked labels.
- Procedural fallback role: fallback/minimal_point.

Negative constraints:
- No glass, chrome, jewel, faceted gem, texture noise, baked labels, background scene, or unrelated particles.
```
