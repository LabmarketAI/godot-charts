# P0 Prompt: `control/handle_linear`

Use for axis-domain endpoints, threshold endpoints, range endpoints, and other constrained one-dimensional analytical handles.

```text
Create control/handle_linear: a linear analytical endpoint handle for dragging min/max chart domains, thresholds, and range endpoints.

Scale:
- World units: Godot/Blender 1.0 unit = 1 meter.
- Intended chart/frame context: a 1.2 m wide spatial analytical chart frame viewed from 1.0-2.0 m in headset and desktop preview.
- Visible body dimensions: 0.10 m diameter, 0.035 m thick.
- Collision/picking proxy: sphere or rounded capsule proxy, 0.16 m diameter minimum.
- Interaction distance: controller ray selection from 1.0-2.0 m and direct grab at 0.35-0.8 m.

Theme:
- Target lookbook: WebXR Dark Instrument first, with Instrument Light-compatible material slots.
- Mood: professional matte analytical instrument, precise, durable, tactile.
- Avoid: toy-like puck, neon arcade, glossy plastic, glass, chrome, sci-fi prop.

Shape:
- Silhouette: rounded capsule puck with shallow equatorial grip groove and separate focus-ring socket.
- Required geometry: body, grip groove, interaction anchor, focus-ring socket, collision proxy.
- Symmetry/origin: centered at local origin; drag axis passes through origin.
- Value-bearing edges/surfaces that must remain exact: center point and local axis alignment.

Interaction vocabulary:
- Supported states: normal, hover, focus, active, disabled, warning, error.
- Input modes: controller ray, direct grab, mouse/pointer, keyboard focus through host controls.
- Required cues: focus ring, hover halo socket, active inset or raised outline, invalid stripe shape, disabled desaturation/outline reduction.
- Cancellation/release behavior: active state must be visually reversible without changing the base silhouette.

Materials and shaders:
- Semantic material slots: control_body, control_focus, control_active, status_warning, status_error, collision_hidden.
- Material model: matte PBR for body; unshaded/emissive low-intensity focus ring allowed.
- Metallic/roughness/alpha/emission constraints: metallic 0.0-0.05, roughness 0.7-0.9, opaque body, no alpha on base body, low emission only for focus/active.
- Shader constraints: outline/halo/active pulse only, with reduced-motion static fallback.

Professional polish:
- Shade smooth: curved body and groove surfaces.
- Keep sharp: local-axis alignment face/socket boundaries.
- Bevel radius/segments: small bevels around exposed edges, 0.004-0.008 m, 3-5 segments.
- Weighted/custom normals: yes, preserve clean broad faces and polished bevels.
- Topology constraints: clean manifold visible mesh, no z-fighting, no accidental low-poly faceting, simple separate collision proxy.

Accessibility:
- Contrast target: focus/invalid outlines reach at least 3:1 non-text contrast in active theme.
- Non-color cues: focus ring shape, active inset/outline, invalid stripe, disabled silhouette/opacity shift.
- Target size/collision: collision target larger than visual body and non-overlapping with adjacent handles.
- Metadata: role, axis/domain binding, current value, min/max constraint supplied by manifest/provider.
- Reduced-motion/alternate input: active pulse has static fallback; no gaze-dwell-only operation.

Export:
- Collections: LOD0, LOD1, COLLISION, SOCKETS, PREVIEW.
- Object prefixes: role__control_handle_linear, lod__, collision__, socket__, origin__, preview__.
- Include: selected runtime mesh, material slots, normals/tangents where needed.
- Exclude: cameras, lights, background scenes, concept geometry, baked text labels.
- Procedural fallback role: fallback/minimal_handle.

Negative constraints:
- No glass, chrome, neon, toy-like plastic, decorative screws, background scene, baked labels, unrelated parts, or rough faceted placeholder geometry.
```
