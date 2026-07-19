## Why

The chart rebuild now has semantic asset roles, a procedural fallback factory, and a broad visual-system spec, but it does not yet define how production-quality chart assets will be authored, reviewed, exported, validated, and consumed. Without a method, asset work can drift into attractive but unusable geometry: wrong pivots, oversized meshes, missing collision proxies, unclear semantic sockets, or WebXR-hostile materials.

We need a repeatable pipeline that treats chart assets as analytical instruments. Blender should be the canonical geometry authoring environment because chart components require precise dimensions, pivots, axes, sockets, naming, collision proxies, LODs, and GLB export discipline. ComfyUI may support concept art, texture/material exploration, and swatches, but generated assets must not become the source of truth until they pass the same manifest and validation gates.

## What Changes

- Define Blender MCP as the primary authoring path for official GLB asset packs.
- Define ComfyUI as an optional support path for references, material studies, icon concepts, and texture inputs, not baseline semantic geometry.
- Introduce a chart asset workbench method: role brief, Blender scene template, semantic naming, material sockets, collision proxies, LOD collections, GLB export, Godot import, validator, gallery review, and renderer integration.
- Create the first production component scope for structural guides, common marks, analytical controls, state overlays, labels/legend anchors, and WebXR cursors/fallbacks.
- Require every GLB-backed role to preserve typed-GDScript procedural fallback behavior.
- Add acceptance gates for pivots, dimensions, triangle/material budgets, collision targets, role metadata, WebXR compatibility, license/provenance, and visual gallery coverage.

## Impact

- Primary impact: `addons/godot-charts/assets/visual/`, `addons/godot-charts/assets/meshes/`, `examples/visual-assets/`, renderers that request semantic roles, and WebXR template controls.
- Supporting impact: docs, OpenSpec asset catalog, Blender starter files, validation scripts, import settings, packaging allowlists, and visual regression evidence.
- This change does not replace the broader `spatial-visual-design-system` capability; it turns its asset-pack requirements into an executable production workflow.
