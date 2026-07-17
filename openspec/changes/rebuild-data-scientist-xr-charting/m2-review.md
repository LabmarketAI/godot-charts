# M2 Exit Review

Status: accepted for M2 closure by product-owner continuation on 2026-07-17.

## Delivered vertical slice

The public reference scene now presents the retained scatter and bounded linked table inside an `AnalyticalFrame3D` with deterministic XYZ axes, grids, ticks, axis labels, title, and orientation/reset landmarks. Content, frame, and navigation input have separate ownership. Frame manipulation uses exact begin/preview/commit/cancel transactions with bounded undo/redo and authored reset, and desktop and mocked-XR adapters emit the same device-independent commands.

Compatible replay revisions and a forced live reconnect preserve the user transform, local navigation state, eligible row selection, picking identities, renderer node, `MultiMesh`, frame roots, and guide resources. The clean preview artifact remains pure typed GDScript and requires only standard Godot 4.6.3 or newer.

## Visual and readability evidence

- The public scene exposes the source title, the `Year`, `Sites`, and `Enrollment` axis titles, 11 deterministic source-domain tick labels, retained axes/grid surfaces, and four orientation/reset landmarks.
- Numerical assertions cover tick generation, formatting, missing positional values, degenerate domains, and stable guide lifecycle. The table remains the readable textual alternative for every source row, including the row omitted from positional rendering.
- A persistent on-screen legend documents all modes and controls. Global key handling keeps the controls available when the table owns focus. Navigate mode provides keyboard observer movement and records the pose without changing the frame transform or analytical domains.
- The reference scene loads and reaches revision 1 under the official standard-Godot build. This is structural and automated readability evidence; it is not a substitute for representative human visual, comfort, or assistive-technology evaluation.

## Measured regression budgets

| Gate | Result |
|---|---|
| Guide materialization | 11 active tick labels, 4 retained landmarks, 1 axes surface, and 1 grid surface |
| Manipulation replay | 100 paired desktop/mocked-XR move transactions under a 5-second headless budget; exact state and command-trace parity |
| Interaction lifecycle | No frame node/resource growth across the 100 paired transactions; history remains bounded |
| Frame projection | 100 repeated state applications preserve frame roots, renderer node, and `MultiMesh` |
| Compatible live lifecycle | Two handshakes with one forced reconnect preserve frame/view/selection/picking and retained render resources |
| Existing content update budget | 250 compatible scatter updates and 250 bounded table refreshes each remain under their 5-second headless regression budgets |

The test output records actual elapsed interaction time for each run. These are generous deterministic headless CPU regression ceilings, not claims about graphical desktop frame time, GPU cost, stereo rendering, WebXR, or headset capacity.

## Dependency decisions

- M2 adds no runtime, editor, native, .NET, XR-package, or network dependency. Product-owned code is limited to frame state/presentation, scientific guide projection, normalized commands, and thin input translation required by the contract.
- Standard Godot supplies scene, mesh, text, input, and WebSocket primitives. The separately pinned Python WebSocket fixture remains test-only and is not shipped in the addon.
- Production OpenXR/WebXR and XR Tools integration remains deferred behind an optional capability adapter and a current dependency scorecard. The mocked-XR adapter proves the command boundary but does not validate a runtime, browser, controller, hand, or headset.
- GdUnit4 remains an approved but unintroduced development option; the official-Godot native `SceneTree` suites remain the dependency-free fallback.

## Remaining risks

- No representative user has yet judged label legibility, occlusion, depth cues, control discoverability, motion comfort, seated/standing reach, or interior/exterior readability.
- Keyboard navigation exists, but focus order, screen-reader behavior, text scaling, high contrast, color-vision-safe encodings, reduced motion, touch, and non-pointer alternatives need formal accessibility evaluation.
- There are no graphical frame-time, GPU, allocation/memory, native stereo-XR, browser/WebXR, headset, controller, direct-hand, or capability-loss measurements.
- Rotation is covered by device-independent commands, but the reference keyboard workflow currently demonstrates move and resize. Analytical zoom, brushing, parameters, persistence, permissions, compound layout, and additional chart families remain deferred.
- The legacy mixed C#/GDScript addon remains beside the clean preview and is not part of the generated artifact.

## Review decision and next gate

M2 satisfies its bounded architectural gate and is closed. It proves a readable, retained, reversible analytical frame and a device-independent interaction seam without selecting a production XR stack.

This review does **not** authorize production WebXR/OpenXR wiring, Jupyter discovery or authentication, or additional chart-family implementation. Before any one of those dependency-bearing slices starts, the product owner must select it explicitly and its implementation plan must record the relevant dependency/capability scorecard, platform and security boundaries, measurable acceptance fixture, and fallback. Until that selection, the safe continuation is governance, documentation, visual-baseline preparation, and benchmark instrumentation that does not pre-commit the next product slice.
