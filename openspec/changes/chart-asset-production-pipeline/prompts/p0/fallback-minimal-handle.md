# P0 Prompt: `fallback/minimal_handle`

Use for the guaranteed procedural or GLB fallback when richer handle assets are missing, invalid, or over budget.

```text
Create fallback/minimal_handle: the simplest professional fallback handle for all chart-critical interactive controls.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: usable in any spatial chart frame, especially WebXR fallback mode.
- Visible body dimensions: 0.11 m diameter sphere/capsule or rounded cube equivalent.
- Collision/picking proxy: 0.18 m sphere proxy minimum.
- Interaction distance: controller ray from 1.0-2.0 m and direct grab at 0.35-0.8 m.

Theme:
- Target lookbook: WebXR Dark Instrument fallback.
- Mood: minimal but finished, professional, readable, not temporary.
- Avoid: unshaded debug cube look, rough low-poly placeholder, editor gizmo appearance.

Shape:
- Silhouette: smooth sphere, capsule, or rounded cube with a single orientation notch.
- Required geometry: body, optional notch, collision proxy.
- Symmetry/origin: centered at local origin.
- Value-bearing edges/surfaces that must remain exact: center/origin.

Interaction vocabulary:
- Supported states: normal, hover, focus, active, disabled, warning, error.
- Input modes: controller ray, direct grab, mouse/pointer.
- Required cues: can accept external focus ring and hover halo; body may scale subtly for active state.
- Cancellation/release behavior: no geometry deformation required.

Materials and shaders:
- Semantic material slots: data_color or control_body, control_focus, status_warning, status_error, collision_hidden.
- Material model: unshaded or matte PBR.
- Metallic/roughness/alpha/emission constraints: metallic 0.0, roughness 0.8-1.0, opaque body.
- Shader constraints: none required; must work without custom shader.

Professional polish:
- Shade smooth: all curved surfaces.
- Keep sharp: orientation notch if present.
- Bevel radius/segments: if rounded cube, bevel 0.008-0.012 m with weighted normals.
- Weighted/custom normals: required for rounded cube; optional for sphere/capsule.
- Topology constraints: no obvious faceting at headset distance, low detail but not low-poly styled.

Accessibility:
- Contrast target: external focus ring or material contrast supports 3:1 non-text contrast.
- Non-color cues: shape/notch and external ring/halo states available.
- Target size/collision: collision proxy is larger than visual body.
- Metadata: role/name/value supplied by provider.
- Reduced-motion/alternate input: no animation required.

Export:
- Collections: LOD0, LOD1, COLLISION, SOCKETS, PREVIEW.
- Object prefixes: role__fallback_minimal_handle, lod__, collision__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals.
- Exclude: cameras, lights, background scenes, concept geometry, baked text labels.
- Procedural fallback role: fallback/minimal_handle.

Negative constraints:
- No debug cube, no faceted ico-sphere look, no text, no logo, no decorative parts, no glass, no chrome, no background scene.
```
