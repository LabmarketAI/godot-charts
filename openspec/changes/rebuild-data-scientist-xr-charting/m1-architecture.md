# M1 Architecture Boundaries

The M1 preview has one dependency direction:

```text
schemas -> protocol -> core <- renderers
                         ^ <- tables
interactions ------------| <- session -> diagnostics
optional integrations -> protocol/session ports (none required by M1)
frames (state) -> frame/core state; future frame presentation -> renderer/table ports
```

## Ownership

| Boundary | Owns | Must not own |
|---|---|---|
| `core/` | Figure/view/layer/table/guide/scale state, validation, serialization, diffs | Nodes, controls, meshes, replay, transport, XR, authentication |
| `frames/` | Scene-independent frame/binding identity, transform, bounds/aspect, chrome/status references, authored reset and local-view state | Nodes, rendering, transport, replay, persistence, device APIs, legacy/demo orchestration |
| `protocol/` | Envelope validation, ordering, limits, revisions, deterministic replay | Network sockets, Python objects, scene rendering |
| `renderers/` | Godot nodes, meshes, materials, data-to-world instances, pick records, and retained frame presentation projected from frame state | Source schemas, transport, session policy, persistence, or device input policy |
| `tables/` | Bounded Godot table projection and row inspection | Source mutation, dataframe execution, transport |
| `interactions/` | Device-independent normalized row selection plus frame modes, capture, reversible commands, and bounded history | Mouse/controller/hand APIs, rendering ownership, transport, persistence |
| `session/` | Atomic coordination of validated model, renderer, table, and selection revisions | Authentication, network transport, source execution |
| `diagnostics/` | Read-only snapshots of public component state | A second mutable state store or credentials |
| `integrations/` | Future optional transport, backend, XR, authentication, and GIS adapters | Mandatory baseline behavior; absent in M1 |

Core and frame-state classes extend `RefCounted` only. Renderer and table adapters receive core models through public methods. Interaction state uses stable row identities and duck-typed ports so it has no renderer or input-device import. The generated preview allowlist and `check-m1-boundaries.sh` enforce these rules in CI.

The legacy `charts/`, `circuits/`, `utils/`, and `widgets/` trees are outside this dependency graph. They are excluded from the preview artifact and may not be imported by M1 code.
