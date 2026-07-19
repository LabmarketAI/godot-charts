# P0 Prompt: `control/focus_ring`

Use for focus, keyboard/ray accessibility focus, selected handles, and active control outlines.

```text
Create control/focus_ring: a reusable focus and selection outline ring for chart controls, handles, buttons, and grab anchors.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: overlays on controls in spatial chart frames viewed from 1.0-2.0 m.
- Visible body dimensions: normalized outer diameter 0.14 m, ring thickness 0.008-0.012 m, scalable by provider.
- Collision/picking proxy: none by default; visual overlay only unless explicitly bound to a control.
- Interaction distance: visible under controller ray, direct grab, and desktop pointer focus.

Theme:
- Target lookbook: WebXR Dark Instrument and Instrument Light.
- Mood: precise, accessible, professional, readable, restrained.
- Avoid: neon glow tube, magic aura, decorative bokeh, heavy bloom.

Shape:
- Silhouette: clean circular or rounded-square ring with small gap/notch option for orientation.
- Required geometry: ring mesh, optional notch, socket alignment marker.
- Symmetry/origin: centered at local origin, lies in local XY plane unless provider orients it.
- Value-bearing edges/surfaces that must remain exact: none; it is state overlay only.

Interaction vocabulary:
- Supported states: focus, selected, active, warning, error.
- Input modes: controller ray, mouse/pointer, keyboard focus, accessibility focus.
- Required cues: shape outline must distinguish focus from hover; warning/error may add stripe/notch variant.
- Cancellation/release behavior: ring can appear/disappear or change thickness without shifting target geometry.

Materials and shaders:
- Semantic material slots: control_focus, control_selected, control_active, status_warning, status_error.
- Material model: unshaded preferred; low-intensity emissive allowed in WebXR dark theme.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, roughness irrelevant for unshaded, alpha only if contrast remains valid, no bloom dependency.
- Shader constraints: optional static halo or slow pulse with reduced-motion disabled state.

Professional polish:
- Shade smooth: ring curves.
- Keep sharp: notch ends if used.
- Bevel radius/segments: subtle bevel 0.002-0.004 m if PBR variant; otherwise clean flat/unshaded ring.
- Weighted/custom normals: yes if PBR bevel variant is used.
- Topology constraints: no visible faceting at headset distance, no z-fighting with base control when offset by provider.

Accessibility:
- Contrast target: at least 3:1 non-text contrast against adjacent control/background colors.
- Non-color cues: ring thickness, notch/stripe, or double-ring variant distinguishes selected/warning/error.
- Target size/collision: visual ring does not reduce or obscure collision target.
- Metadata: supplied by owning control; ring must not contain baked text.
- Reduced-motion/alternate input: static focus variant required.

Export:
- Collections: LOD0, LOD1, SOCKETS, PREVIEW.
- Object prefixes: role__control_focus_ring, lod__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals/tangents where needed.
- Exclude: collision unless requested, cameras, lights, background scenes, concept geometry, baked text labels.
- Procedural fallback role: control/focus_ring procedural provider.

Negative constraints:
- No neon arcade glow, no magic aura, no bloom dependency, no decorative particles, no text, no logo, no background scene.
```
