# M2 Interactive Analytical Frame Decision

Status: authorized next implementation gate, 2026-07-17.

## Decision

The next vertical slice is one interactive analytical frame around the existing retained scatter/session implementation. It is selected ahead of broader Matplotlib coverage, more chart families, real Jupyter authentication/discovery, compound figures, and direct WebXR integration.

The current rebuild proves the difficult data boundary—safe Python adaptation, normalized envelopes, recorded/live transport parity, retained state, incremental scatter rendering, bounded table inspection, linked selection, revisions, and diagnostics—but it still presents an engineering fixture rather than a usable spatial scientific instrument. The product's differentiator is embodied analysis. A frame, readable guides, and unambiguous manipulation therefore provide more architectural and user value than another producer or mark while exercising nearly every completed subsystem.

## Legacy evidence to adapt, not port

The legacy implementation demonstrates desired behaviors: frame creation and sizing, placement previews, move mode, direct XR grabbing, topic routing, workspace transforms, sliders, focus, teleport/focus, and circuit/chart hosting. It also demonstrates the failure modes M2 must remove: GDScript wrappers over C#, destructive chart rebuilds, demo-owned orchestration, chart-specific data dictionaries, device events embedded in controls, and ambiguous ownership between frame, content, navigation, binding, and persistence.

M2 may reproduce externally visible behavior only through the new retained model and public ports. It SHALL NOT extend or import `charts/`, `widgets/`, legacy `utils/`, or `demo/` services.

## State and ownership

- Frame state owns spatial identity, transform, bounds, chrome/status references, lock/visibility, authored reset state, and frame-local view state.
- Plot state owns analytical figure/view/layer/table/scale/guide semantics.
- Binding state identifies static, replayed, live, derived, or snapshot content without owning its publisher.
- Session coordination applies validated plot revisions while preserving eligible frame, view, selection, table, and picking state.
- Commands own reversible state transitions; input adapters translate devices into intents and never mutate frame state directly.
- Presentation nodes render state and expose picking/handle ports; they are not authoritative persistence stores.

## Interaction boundary

M2 has three modes:

- `content`: inspect/select marks and table rows; future chart zoom, brush, and analytical handles route here.
- `frame`: select and manipulate the whole spatial frame through explicit handles/capture.
- `navigate`: change observer or chart-view orientation without moving the frame or silently changing analytical domains.

Every manipulation follows begin → preview → commit or cancel. Committed changes enter bounded undo/redo history. Lock and capture loss reject or cancel mutations predictably. Reset returns to the authored frame/view state and does not request source-data replacement.

## Rendering boundary

The existing retained guide metadata becomes visible through deterministic XYZ axes, grid, ticks, labels, title, and interior orientation/reset landmarks. Guides use shared resources and update incrementally. Labels and landmarks must remain interpretable from outside and within the coordinate volume; graphical depth may aid orientation but may not distort perceived values.

## Deferred scope

M2 does not implement general frame grouping/layout, docking, persistence, permissions, compound figures, analytical domain zoom, brushing, filters, sliders/parameters, real OpenXR/WebXR APIs, hand tracking, Jupyter connection profiles, authentication, notebook/kernel discovery, new chart families, Qiskit, or GIS. It reserves ports and command semantics for those capabilities without speculative implementations.

## Evidence required for closure

Closure requires the automated and public-scene evidence listed in `tasks.md`: readable scientific guides; exact reversible commands; mode/capture disambiguation; desktop and mocked-XR parity; replay/live revision preservation; stable retained resources; clean standard-Godot packaging; and a review that explicitly authorizes the next dependency-bearing slice.
