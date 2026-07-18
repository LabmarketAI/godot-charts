# Godot Charts M1 Preview

This is a generated, pure typed-GDScript preview artifact for the M1 architectural spine. Copy this directory to `res://addons/godot-charts/` and enable the plugin in a standard Godot 4.6.3-or-newer project.

The optional `integrations/websocket_session_client.gd` adapter uses Godot's built-in `WebSocketPeer` and introduces no runtime package dependency. Recorded replay continues to work when the integration is unused.

The preview also carries the scene-independent M2 `frames/` state contracts. They do not create presentation nodes or require an input/XR package; consumers may serialize frame and binding state independently of its presentation.

`renderers/analytical_frame_3d.gd` is the retained presentation shell for that state. It supplies stable content, guide, chrome, and handle roots and can own the current scatter renderer without owning replay, transport, persistence, or device behavior.

`renderers/cartesian_guides_3d.gd` and `core/linear_ticks.gd` provide the first readable scientific-guide tier: deterministic linear XYZ ticks, retained axes/grids, pooled labels, source axis titles, figure title, and orientation/reset landmarks. Broader scale types, collision layout, legends, and theme packs remain later capabilities.

`interactions/frame_interaction_controller.gd` provides device-independent content/frame/navigate modes and reversible frame transactions. Thin desktop mouse/keyboard and deterministic mocked-XR ray/grab adapters translate semantic application events through a shared intent router. They import no mouse, OpenXR, WebXR, or XR Tools API, so production event wiring stays optional and outside the controller.

`interactions/axis_domain_interaction_controller.gd` provides the first chart-native analytical-control slice. It mutates retained X/Y/Z linear scale domains through begin/preview/commit/cancel operations, reapplies the retained figure through the frame port, and rejects unsupported or invalid domain transitions. XR Tools presentation remains outside this controller; the tracked WebXR template supplies one headset-facing example.

`assets/visual/` contains the first semantic procedural asset layer: role ids, token resources, a low-cost factory, a gallery node, and a manifest for WebXR-performance chart/control assets.

The preview contains the recorded-session protocol, retained plotting model, scatter renderer, bounded table, linked selection, coordinated replacement, diagnostics, and versioned schemas. It intentionally excludes the legacy C# chart API and demo application.
