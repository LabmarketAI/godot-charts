# Godot Charts M1 Preview

This is a generated, pure typed-GDScript preview artifact for the M1 architectural spine. Copy this directory to `res://addons/godot-charts/` and enable the plugin in a standard Godot 4.6.3-or-newer project.

The optional `integrations/websocket_session_client.gd` adapter uses Godot's built-in `WebSocketPeer` and introduces no runtime package dependency. Recorded replay continues to work when the integration is unused.

The preview also carries the scene-independent M2 `frames/` state contracts. They do not create presentation nodes or require an input/XR package; consumers may serialize frame and binding state independently of its presentation.

`renderers/analytical_frame_3d.gd` is the retained presentation shell for that state. It supplies stable content, guide, chrome, and future-handle roots and can own the current scatter renderer without owning replay, transport, persistence, or device behavior.

`renderers/cartesian_guides_3d.gd` and `core/linear_ticks.gd` provide the first readable scientific-guide tier: deterministic linear XYZ ticks, retained axes/grids, pooled labels, source axis titles, figure title, and orientation/reset landmarks. Broader scale types, collision layout, legends, and theme packs remain later capabilities.

`interactions/frame_interaction_controller.gd` provides device-independent content/frame/navigate modes and reversible frame transactions. It has no mouse or XR dependency; platform adapters translate their events into its begin/preview/commit/cancel and history API.

The preview contains the recorded-session protocol, retained plotting model, scatter renderer, bounded table, linked selection, coordinated replacement, diagnostics, and versioned schemas. It intentionally excludes the legacy C# chart API and demo application.
