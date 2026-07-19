# P0 Prompt: `structure/axis_line`

```text
Create structure/axis_line: a precise scalable axis shaft for scientific 3D chart coordinate systems.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: normalized 1.0 m axis segment for chart frames between 0.8-1.5 m wide, viewed from 1.0-2.0 m.
- Visible body dimensions: normalized length 1.0 m, thickness 0.006-0.012 m depending theme.
- Collision/picking proxy: none by default; optional if paired with control/axis_grip.
- Interaction distance: readable in headset and desktop preview.

Theme:
- Target lookbook: Instrument Light first, WebXR Dark Instrument variant.
- Mood: crisp, quiet, measurable, professional.
- Avoid: decorative rods, glowing cage, heavy beveled rail, toy-like pipe.

Shape:
- Silhouette: straight thin rectangular prism or smooth tube variant, exact endpoints.
- Required geometry: shaft, optional endcap socket.
- Symmetry/origin: centered at local origin with length along local X unless provider remaps.
- Value-bearing edges/surfaces that must remain exact: endpoints and centerline.

Interaction vocabulary:
- Supported states: normal, disabled, warning only if axis invalid.
- Input modes: noninteractive structure unless paired with axis grip.
- Required cues: axis identity must not rely only on hue; endcap/label anchor may provide redundant cue.
- Cancellation/release behavior: not applicable.

Materials and shaders:
- Semantic material slots: structure_quiet, status_warning.
- Material model: unshaded or matte PBR.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, roughness 0.8-1.0, opaque baseline, no emission.
- Shader constraints: no animation or glow.

Professional polish:
- Shade smooth: tube variant only.
- Keep sharp: rectangular variant faces and endpoints.
- Bevel radius/segments: none for exact rectangular value edge; tube variant may use smooth circular profile.
- Weighted/custom normals: yes for rectangular variant if bevels are introduced.
- Topology constraints: exact length, no visible wobble, no accidental faceting in tube variant.

Accessibility:
- Contrast target: visible enough in high-contrast theme; subordinate in default themes.
- Non-color cues: label/endcap support axis identity.
- Target size/collision: not an interactive target unless promoted to axis grip.
- Metadata: axis id supplied by renderer/provider.
- Reduced-motion/alternate input: no motion.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__structure_axis_line, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked labels.
- Procedural fallback role: fallback/minimal_line.

Negative constraints:
- No decorative rail, no glow cage, no imprecise endpoints, no baked text, no background scene.
```
