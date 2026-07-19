# ComfyUI / Text-to-3D Reference Prompt Template

Use this only for concepts, material studies, texture references, or GLB drafts. Generated outputs must be restated as Blender/Godot asset briefs before they can ship.

```text
[Single asset object], [shape and silhouette], [material], [one lookbook style], [use case], [scale cue], [technical constraints].

For a Godot WebXR charting asset. Professional polished geometry, clean topology, smooth curved surfaces, crisp intentional edges, matte nonmetal material, no background scene, no text labels, no decorative unrelated objects, no low-poly faceting unless explicitly requested.
```

## Required Negative Prompt

```text
no background scene, no extra objects, no baked text, no logos, no characters, no hands, no decorative screws, no glass, no chrome, no toy-like material, no neon arcade style, no rough low-poly faceting, no fused floating pieces
```

## Required Follow-Up

After a useful reference is generated:

1. Identify the semantic role it might support.
2. Rewrite it as a compliant Blender asset prompt.
3. Add exact scale, pivot, collision, material sockets, LOD, fallback, and accessibility requirements.
4. Treat the generated output as a draft until Blender cleanup and Godot validation pass.
