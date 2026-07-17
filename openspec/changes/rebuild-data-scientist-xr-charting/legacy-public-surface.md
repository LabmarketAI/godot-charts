# Legacy Public Surface and Consumer Disposition

Status: M1 migration inventory accepted 2026-07-16. This records compatibility decisions, not a promise to preserve the legacy API.

## Registered addon surface

The legacy plugin registers 26 editor types and two autoloads. The registered families are:

| Family | Registered names | M1 disposition |
|---|---|---|
| Data sources | `ChartDataSource`, `DictDataSource`, `CSVDataSource`, `StreamDataSource`, `GraphNetworkDataSource` | Adapt source/update intent into normalized table, plot-message, and future catalog/transport contracts; do not retain Chart.js dictionaries as the canonical API. |
| Frames | `ChartFrame3D` | Adapt placement/transform intent in later frame-session work; M1 proves transform preservation but does not publish the legacy node. |
| Charts | `PointChart3D`, `BarChart3D`, `LineChart3D`, `ScatterChart3D`, `SurfaceChart3D`, `HistogramChart3D`, `GraphNetworkChart3D` | Rewrite against retained figure/view/layer models. M1 replaces scatter only; remaining marks are deferred. |
| Quantum | `CircuitChart3D` | Preserve intent and fixtures; rewrite under the Qiskit capability without .NET JSON/graph packages. |
| Widgets | `WidgetPanel3D`, row/column/grid/stack containers, theme data, control, label, button, toggle, slider, list item | Adapt only normalized focus/control/parameter behavior needed by analytical interaction. Do not ship the generic widget system as M1 core. |
| Autoloads | `WidgetFocusManager`, `WidgetThemeManager` | Remove as mandatory globals. Future focus/theme services use explicit optional bindings. |

The registered chart/data GDScripts are wrappers over C# implementations, not independent GDScript APIs. Their exported properties, signals, Chart.js-shaped dictionaries, resource paths, and serialized scene types are therefore legacy-only.

## Additional code surfaces

- Twenty-five addon C# files implement charts, circuit loading, data sources, statistics/routing helpers, and widget schema/theme tooling.
- Legacy GDScript widget controls expose focus, pointer, pressed/toggled/value-changed, sizing, layout, and theme properties. These are behavioral evidence for later analytical controls.
- NUnit tests cover selected binning, circuit, routing, and widget helpers with Godot stubs; they do not establish current chart/plugin compatibility.
- Demo services own message bus, WebSocket, binding, frame orchestration, workspace persistence, desktop/VR controllers, and data generation. They are consumers/evidence, never M1 dependencies.

## Known in-repository consumers

The separate `demo/` project consumes every legacy chart family, circuit rendering, frame orchestration, message/WebSocket services, workspace behavior, and widgets. No independent consumer package or stable external serialized-scene contract is present in this repository. The clean M1 example consumes only preview public scripts and schemas.

## Compatibility decision

M1 takes a clean-break preview namespace/package. The legacy API remains in the repository during migration but is excluded from the preview artifact. A compatibility adapter will be approved only if an identified external consumer supplies concrete node/property/signal/serialization requirements and accepts its maintenance cost. Otherwise migration documentation will map concepts, not preserve class inheritance or serialized node types.

Product-owner continuation after the M1 review accepts this disposition for the architectural spine. It does not authorize deleting legacy code before remaining demo/circuit evidence is captured.
