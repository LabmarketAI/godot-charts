# Blender Asset Prompt Template

Use this template for Blender MCP work and artist handoff.

```text
Create [role id]: [concrete asset object] for [chart function].

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: [frame size, chart mode, viewing distance].
- Visible body dimensions: [meters or centimeters].
- Collision/picking proxy: [shape and dimensions].
- Interaction distance: [direct reach / ray / desktop use].

Theme:
- Target lookbook: [Instrument Light | Editorial Presentation | WebXR Dark Instrument].
- Mood: [professional attributes].
- Avoid: [forbidden style/materials].

Shape:
- Silhouette: [shape and proportions].
- Required geometry: [parts].
- Symmetry/origin: [requirements].
- Value-bearing edges/surfaces that must remain exact: [list].
- Icon/state overlay discipline: [default visible marks only; state overlays as sockets/variants, no stacked visible state previews].

Interaction vocabulary:
- Supported states: [normal, hover, focus, selected, active, disabled, warning, error].
- Input modes: [controller ray, direct grab, mouse/pointer, keyboard focus].
- Required cues: [outline, ring, groove, stripe, inset, scale, etc.].
- Cancellation/release behavior: [visual requirement].

Materials and shaders:
- Semantic material slots: [list].
- Material model: [PBR/unshaded].
- Metallic/roughness/alpha/emission constraints: [values].
- Shader constraints: [allowed effects and fallback].

Professional polish:
- Shade smooth: [surfaces].
- Keep sharp: [surfaces].
- Bevel radius/segments: [range].
- Weighted/custom normals: [yes/no and where].
- Topology constraints: [clean mesh, no z-fighting, no accidental faceting].

Accessibility:
- Contrast target: [non-text/text where applicable].
- Non-color cues: [states].
- Target size/collision: [requirements].
- Metadata: [role/name/value].
- Reduced-motion/alternate input: [requirements].

Export:
- Collections: LOD0, LOD1, COLLISION, SOCKETS, PREVIEW.
- Object prefixes: role__, lod__, collision__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals/tangents where needed.
- Exclude: cameras, lights, background scenes, concept geometry, baked text labels.
- Procedural fallback role: [fallback role].

Negative constraints:
- [No glass/chrome/toy look/etc.]
- [No background scene.]
- [No baked labels.]
- [No unrelated decorative parts.]
- [No stacked visible state overlays or alternate icon variants in the default asset.]
```
