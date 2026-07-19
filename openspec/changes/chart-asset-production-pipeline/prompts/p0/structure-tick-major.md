# P0 Prompt: `structure/tick_major`

```text
Create structure/tick_major: a major tick mark for scientific chart axes.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: tick marks on axis lines for 0.8-1.5 m spatial chart frames viewed from 1.0-2.0 m.
- Visible body dimensions: 0.045 m length, 0.006-0.01 m thickness.
- Collision/picking proxy: none.
- Interaction distance: readable at headset and desktop preview distance.

Theme:
- Target lookbook: Instrument Light with WebXR Dark Instrument variant.
- Mood: exact, quiet, readable, subordinate to data.
- Avoid: decorative notch, thick ruler block, glowing marker.

Shape:
- Silhouette: short straight line segment perpendicular to axis, centered on tick coordinate.
- Required geometry: one tick segment, optional label-anchor socket.
- Symmetry/origin: origin at tick coordinate center.
- Value-bearing edges/surfaces that must remain exact: center coordinate and perpendicular orientation.

Interaction vocabulary:
- Supported states: normal, disabled/warning only through material if scale invalid.
- Input modes: noninteractive.
- Required cues: major tick visually stronger than minor tick.
- Cancellation/release behavior: not applicable.

Materials and shaders:
- Semantic material slots: structure_quiet.
- Material model: unshaded or matte PBR.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, high roughness, opaque, no emission.
- Shader constraints: none.

Professional polish:
- Shade smooth: only if cylindrical variant.
- Keep sharp: rectangular segment endpoints and sides.
- Bevel radius/segments: none unless theme variant requires tiny non-value bevel away from coordinate center.
- Weighted/custom normals: optional for rectangular variant.
- Topology constraints: exact center, no wobble, no faceted cylinder if tube variant.

Accessibility:
- Contrast target: visible enough in high-contrast theme.
- Non-color cues: major tick length/thickness differs from minor tick.
- Target size/collision: noninteractive.
- Metadata: tick value supplied by renderer/provider, not baked.
- Reduced-motion/alternate input: no motion.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__structure_tick_major, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked labels.
- Procedural fallback role: fallback/minimal_line.

Negative constraints:
- No text labels in mesh, no glow, no decorative ruler marks beyond one tick, no background scene.
```
