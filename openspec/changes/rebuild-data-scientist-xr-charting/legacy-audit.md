# Legacy Audit for M1

Status: initial repository audit, 2026-07-16. This record covers the evidence needed to start M1; public API and performance inventories remain open.

## Observed baseline

The distributable path is correctly rooted at `addons/godot-charts/`, but it is not currently a standard-Godot addon. It contains 25 C# sources and 30 GDScript sources. Most chart and data-source GDScripts are thin wrappers that extend C# implementations, so installing the directory requires a .NET-enabled Godot project even though the package is presented as GDScript.

The demo is also a .NET project and contains application services that do not belong to the addon. Current automated tests are NUnit tests which compile selected C# helpers against Godot stubs. CI checks addon-copy synchronization and runs those .NET tests; it does not run Godot, validate a clean standard-Godot install, or exercise GDScript.

The legacy renderer regenerates chart children and `ImmediateMesh` geometry on rebuild. This is useful visual and behavioral evidence, but it does not satisfy M1's retained identity, incremental update, or resource-lifecycle requirements. The demo message bridge accepts a small `{topic, payload}` envelope without schema negotiation, stable session identity, ordering, idempotency, revisions, flow control, or resynchronization.

## Initial subsystem disposition

| Surface | Decision | Evidence and boundary |
|---|---|---|
| Addon install location and `plugin.cfg` | Keep | Already follows the Godot `addons/<plugin>/` convention. The release artifact must remain this directory only. |
| C# chart nodes and two-line GDScript wrappers | Rewrite | They impose .NET and rebuild scene geometry destructively. Preserve representative appearance and public behavior as fixtures, not the inheritance structure. |
| Data-source concepts (dictionary, CSV, stream) | Adapt | Source separation and update signals are useful. Replace the chart-specific dictionary shape with normalized, versioned plot/table contracts and stable identities. |
| Axis, tick, grid, legend, palette behavior | Adapt | Retain as visual-reference fixtures. Reimplement through shared retained guides, scales, themes, and batched rendering. |
| Circuit loader/rendering intent and Qiskit fixtures | Adapt | Preserve circuit identity and visualization intent under the later quantum capability; remove .NET JSON and graph dependencies from core. |
| Widget controls and focus concepts | Adapt selectively | Sliders, focus, and spatial controls inform the normalized interaction layer. Do not make the generic legacy widget framework an M1 dependency. |
| Graph layout and statistics helpers | Optional integration or rewrite minimally | QuikGraph, MSAGL, and MathNet are .NET-only. Defer graph layout; implement only scatter-scale math required by M1 using GDScript. |
| Demo message bus and WebSocket bridge | Remove from core; adapt as later integration evidence | Transport details must sit behind the normalized session protocol. M1 uses deterministic recorded replay. |
| Demo frame/workspace orchestration | Adapt as product-behavior evidence | Frame binding, routing, and persistence belong to later session capabilities, not the M1 runtime spine. |
| Demo addon mirror | Remove when clean install harness lands | A duplicated addon creates drift. Until removal, it remains generated and must never be edited directly. |
| NUnit/stub test project | Keep temporarily | It protects legacy helpers during migration. Add a separate standard-Godot/GdUnit4 lane, then retire .NET tests with the corresponding legacy code. |

## M1 migration boundary

New work must not extend a C# class or import demo code. The permanent boundaries are:

- `core`: pure typed-GDScript plot/table state, identity, validation, scales, and diffs;
- `protocol`: versioned envelopes, limits, revisions, diagnostics, and deterministic replay;
- `renderers`: Godot scene/rendering adapters that consume core state;
- `interactions`: device-independent intents and linked selection state;
- `integrations`: optional transports, Python/Jupyter, XR, GIS, and authentication adapters.

The first vertical slice is one recorded Python-originated scatter plot and bounded table. It is intentionally offline and must install into a clean standard-Godot project with no demo, .NET, native binary, or network requirement.

## Remaining audit evidence

- Enumerate the legacy public nodes, properties, signals, serialized shapes, and known consumers.
- Capture reproducible legacy scatter and circuit smoke scenes before replacement.
- Measure current correctness, lifecycle growth, and desktop performance on those scenes.
- Confirm the Godot version floor and supported platform/export matrix.
- Obtain product-owner approval for removals and any compatibility adapter.
