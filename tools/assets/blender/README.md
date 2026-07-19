# Blender Chart Asset Starter

This directory contains the Blender starter scene for Godot Charts asset authoring.

Regenerate the starter scene with:

```bash
blender --background --python tools/assets/blender/create_chart_asset_starter_scene.py
```

Output:

```text
tools/assets/blender/chart_asset_starter.blend
```

The scene establishes:

- metric units where `1 Blender unit = 1 meter`
- Godot-friendly collection layout: `LOD0`, `LOD1`, `COLLISION`, `SOCKETS`, `PREVIEW`
- semantic material slots used by the asset manifest
- scale references for a 1.7m user, a 1.2m chart frame, 0.8m reach radius, and 10cm handle body
- an example `control/handle_linear` body with bevel and weighted-normal polish
- collision and socket examples that should be excluded from visible runtime geometry unless used by the importer

Runtime GLB exports should select only the role-specific objects required by the asset prompt. Do not export reference figures, cameras, lights, or concept geometry.
