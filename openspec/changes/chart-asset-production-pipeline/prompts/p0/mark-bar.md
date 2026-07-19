# P0 Prompt: `mark/bar`

```text
Create mark/bar: a scalable bar/column mark for bar charts and histograms.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: instanced bars in categorical/continuous charts viewed from 1.0-2.0 m.
- Visible body dimensions: normalized 0.10 m x 0.10 m footprint and 1.0 m height along local value axis, renderer scales to data.
- Collision/picking proxy: renderer/provider may add picking bounds matching data bar extents.
- Interaction distance: readable in desktop and headset views.

Theme:
- Target lookbook: Instrument Light.
- Mood: precise, matte, sturdy, professional.
- Avoid: toy blocks, glossy plastic, rounded candy bars, decorative pillars.

Shape:
- Silhouette: square or subtly rounded rectangular column.
- Required geometry: baseline pivot, value-axis body, material slot.
- Symmetry/origin: baseline-center pivot at local origin; height grows along local +Y unless provider remaps.
- Value-bearing edges/surfaces that must remain exact: baseline, top value face, side extents.

Interaction vocabulary:
- Supported states: normal, hover, selected, filtered, disabled, warning.
- Input modes: ray/pointer inspection through renderer picking.
- Required cues: selected outline/edge or halo in addition to color.
- Cancellation/release behavior: not applicable.

Materials and shaders:
- Semantic material slots: data_matte, data_selected_outline, data_filtered, status_warning.
- Material model: matte PBR or unshaded data material.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, roughness 0.75-1.0, opaque baseline.
- Shader constraints: no glossy highlights that obscure top value face; no animated material.

Professional polish:
- Shade smooth: only on tiny non-value bevels if present.
- Keep sharp: baseline, top value face, side faces.
- Bevel radius/segments: optional 0.002-0.004 m edge bevel only if it does not change perceived value boundary.
- Weighted/custom normals: yes if bevels are present.
- Topology constraints: exact baseline-center pivot, no warped faces, no z-fighting.

Accessibility:
- Contrast target: selected/hover edge reaches 3:1 where meaningful.
- Non-color cues: outline/edge pattern/halo available.
- Target size/collision: renderer-level picking tolerance for narrow bars.
- Metadata: series/category/value supplied by renderer/provider.
- Reduced-motion/alternate input: no required animation.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__mark_bar, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked labels.
- Procedural fallback role: fallback/minimal_bar.

Negative constraints:
- No toy blocks, no glossy plastic, no decorative bevel that shifts value, no baked labels, no background scene.
```
