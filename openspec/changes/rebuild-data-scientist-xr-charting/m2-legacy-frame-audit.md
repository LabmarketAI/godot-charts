# M2 Legacy Frame and Interaction Audit

Status: M2.1 implementation evidence, 2026-07-17.

## Reviewed surfaces

- `charts/ChartFrame3D.cs` and its GDScript wrapper;
- demo `FrameOrchestrationService`, `WorkspaceStateService`, `DataBindingService`, console frame controls, desktop frame view, and placement hints;
- `MainVr` placement preview, controller-distance adjustment, wall clamping, grip placement, and move mode;
- generic widget control/focus and slider pointer handling;
- message-bus topic routing and frame routing-profile helpers.

## Behaviors worth preserving

| Behavior | M2 disposition |
|---|---|
| Stable frame identity independent of chart type | Preserve in scene-independent frame state. Do not derive identity from node names or timestamps inside presentation code. |
| Explicit size, transform, visibility, source/status, and display title | Preserve as frame state; use three-dimensional bounds rather than the legacy front-panel-only `Vector2`. |
| Authored placement plus runtime movement | Preserve authored and current transforms so reset is exact and independent of persistence. |
| Content fitted within frame bounds | Preserve behind a presentation port; content renderer remains responsible for analytical coordinates. |
| Placement preview, distance bounds, wall avoidance, and controller-facing yaw | Preserve later as adapter/constraint behavior emitting commands, not frame-state policy. |
| Move-mode selection and direct grip | Preserve as explicit frame-mode capture with begin/preview/commit/cancel. |
| Size presets and readable default placement | Preserve later as caller-authored commands/templates, not hard-coded frame types. |
| Topic/source routing and manual representation lock | Generalize as a transport-neutral binding and `follow_source`, `suggest_source`, `user_locked`, or `derived` representation policy. |
| Workspace transform restoration | Defer persistence, but make state deterministically serializable now. |
| Slider/pointer preview while dragging | Reuse the preview/commit intent, not the device-specific widget implementation. |
| Teleport/focus at a readable distance | Preserve later as navigate-mode behavior using frame bounds. |

## Coupling and correctness gaps

- The frame is a C# `Node3D`; its GDScript file is only a wrapper, so it cannot ship in the standard-Godot baseline.
- `ChartFrame3D` owns panel rendering, child-type discovery, fitting, and repeated destructive rebuilds. Changing presentation properties frees and recreates internal meshes and materials.
- Frame origin is bottom-left while XR placement preview is centered, requiring controller code to know and compensate for presentation geometry.
- The orchestration service owns creation, type switching, routing, display identity, movement, persistence, and node lifecycle in one demo service.
- Runtime identities use wall-clock timestamps and are not deterministic across replay, restore, or distributed sessions.
- Chart type is inferred from child runtime classes, and switching type deletes content nodes; binding and representation intent are not durable state.
- Move and placement operations mutate nodes continuously and persist immediately. There is no transaction, cancel, exact undo, capture-loss behavior, or atomic validation.
- XR controller polling and gesture interpretation live in the application scene; desktop, XR, and widget paths do not emit a shared intent/command contract.
- Workspace JSON has no frame-specific schema validation or migration and mixes application console state with analytical state.
- Topic routing uses demo bus IDs and Chart.js-like chart types rather than normalized plot/data/source descriptors.
- Generic sliders rebuild meshes on value changes and embed mouse/XR branching inside the control, which cannot serve as the device-neutral analytical parameter model.
- Lock, visibility, stale/error status, local chart-view state, authored reset state, provenance, and permissions are absent or distributed across services.

## M2 boundary decision

M2 keeps no legacy class or service as a dependency. It introduces pure `RefCounted` frame/binding state first, then a retained presentation node, command/history owner, and separate desktop/mocked-XR adapters. Persistence, production XR constraints, routing catalogs, permissions, and general widgets remain outside M2 unless a minimal port is explicitly required by its acceptance workflow.
