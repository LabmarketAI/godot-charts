# Visual Asset Layer

This directory contains the first code-native asset-generation pass for the
spatial visual design system. Assets are generated from semantic roles and
theme tokens rather than renderer literals.

Primary entry points:

- `visual_asset_roles.gd` defines stable role ids and sockets.
- `visual_theme_tokens.gd` defines the initial instrument-light and
  WebXR-performance token sets.
- `procedural_visual_asset_factory.gd` creates low-cost Godot nodes for the
  first structural, mark, control, and fallback roles.
- `visual_asset_gallery_3d.gd` instantiates every registered role for visual
  review.
- `asset_pack_manifest.json` documents the initial procedural pack metadata,
  pivots, provider, and performance tiers.

The first pass is intentionally procedural and unshaded so assets remain
portable across desktop, native XR, and WebXR. Renderer integration and richer
pack validation will build on this role/token surface.
