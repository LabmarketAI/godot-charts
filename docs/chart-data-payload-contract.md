# Chart Data Payload Contract

This document defines the canonical JSON contract for demo data publishing and chart subscription workflows.

Current primary consumers:

- #55 (demo message bus foundation)
- #51 (per-frame topic routing)
- #63 (schema validator and importer tooling)

## Goals

- Keep transport simple and deterministic (JSON-only payloads).
- Keep routing concerns in the envelope and rendering values in the chart body.
- Allow additive evolution without breaking existing consumers.

## Canonical Envelope (v1)

All chart updates published on the demo message bus should follow this envelope:

```json
{
  "schema_version": "1.0",
  "topic": "notebook:foo.ipynb/cell:abc123",
  "chart_type": "histogram",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {},
  "style": {
    "color": "#4EA3FF",
    "texture": null
  },
  "meta": {
    "workspace": "default",
    "source": "agentic-jupyter-node"
  }
}
```

### Field requirements

Required fields:

- `schema_version` (string): schema version for payload compatibility checks.
- `topic` (string): subscriber routing key, stable across updates for the same stream.
- `chart_type` (enum): one of `bar`, `line`, `scatter`, `histogram`, `surface`, `graph_network`.
- `timestamp` (string): ISO 8601 UTC timestamp.
- `data` (object): chart-type-specific payload.

Optional fields:

- `style.color` (string): preferred series/base color in `#RRGGBB` format.
- `style.texture` (string or null): optional Godot `res://...` resource path.
- `meta.workspace` (string): logical workspace name.
- `meta.source` (string): publisher identity (for traceability).
- Any additional producer-specific metadata under `meta.*`.

### Decision: texture representation

`style.texture` uses a project-local resource path string (for example `res://assets/textures/noise.png`) or `null`.

Rationale:

- Matches Godot runtime resource loading directly.
- Avoids large base64 payload inflation on frequent updates.
- Keeps the transport contract stable for validator tooling in #63.

## Per-chart `data` payloads

Each sample below is a complete canonical message.

### Bar sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/bar/sales",
  "chart_type": "bar",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "labels": ["Q1", "Q2", "Q3", "Q4"],
    "datasets": [
      { "name": "Revenue", "values": [10.0, 13.5, 12.2, 16.1] }
    ]
  },
  "style": { "color": "#2D9CDB", "texture": null }
}
```

### Line sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/line/telemetry",
  "chart_type": "line",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "datasets": [
      {
        "name": "LatencyMs",
        "points": [
          { "x": 0.0, "y": 11.0, "z": 0.0 },
          { "x": 1.0, "y": 9.6, "z": 0.0 },
          { "x": 2.0, "y": 10.4, "z": 0.0 }
        ]
      }
    ]
  },
  "style": { "color": "#27AE60", "texture": null }
}
```

### Scatter sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/scatter/clusters",
  "chart_type": "scatter",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "datasets": [
      {
        "name": "ClusterA",
        "points": [
          { "x": 0.2, "y": 1.3, "z": 0.5 },
          { "x": 0.4, "y": 1.1, "z": 0.7 },
          { "x": 0.1, "y": 1.6, "z": 0.4 }
        ]
      }
    ]
  },
  "style": { "color": "#EB5757", "texture": null }
}
```

### Histogram sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/histogram/counts",
  "chart_type": "histogram",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "name": "Count",
    "bin_edges": [0.0, 1.0, 2.0, 3.0],
    "counts": [10, 7, 2],
    "binning": {
      "mode": "auto",
      "rule": "freedman_diaconis",
      "fallback": "sturges"
    }
  },
  "style": { "color": "#F2994A", "texture": null }
}
```

Histogram invariants:

- `bin_edges.length = counts.length + 1`
- `bin_edges` is monotonic non-decreasing
- `counts` contains non-negative integers

### Surface sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/surface/heatmap",
  "chart_type": "surface",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "x_labels": ["0", "1", "2"],
    "z_labels": ["0", "1", "2"],
    "values": [
      [0.0, 0.4, 0.8],
      [0.2, 0.7, 1.0],
      [0.1, 0.5, 0.9]
    ]
  },
  "style": { "color": "#9B51E0", "texture": "res://assets/textures/noise.png" }
}
```

### Graph network sample

```json
{
  "schema_version": "1.0",
  "topic": "demo/graph/network",
  "chart_type": "graph_network",
  "timestamp": "2026-03-27T18:00:00Z",
  "data": {
    "nodes": [
      { "id": "n1", "label": "Hub", "x": 0.0, "y": 0.0, "z": 0.0 },
      { "id": "n2", "label": "A", "x": 1.0, "y": 0.2, "z": 0.1 },
      { "id": "n3", "label": "B", "x": -0.6, "y": 0.3, "z": -0.2 }
    ],
    "edges": [
      { "from": "n1", "to": "n2", "weight": 0.8 },
      { "from": "n1", "to": "n3", "weight": 0.5 }
    ]
  },
  "style": { "color": "#56CCF2", "texture": null }
}
```

## Compatibility and migration notes

- `schema_version` must be explicit and semver-like (`1.0`, `1.1`, etc.).
- Consumers should ignore unknown fields for forward compatibility.
- Producers should only add fields in minor schema updates.

Legacy envelope mapping (existing docs or producers) to canonical v1:

- `kind` -> `chart_type`
- `version` -> `schema_version`
- `source.topic` -> `topic`
- `updated_at` -> `timestamp`
- `payload` -> `data`

## Integration guidance

- #51 should use `topic` as the frame routing key and `chart_type` for optional chart compatibility checks.
- #63 should validate required/optional fields and chart-specific `data` shape with chart-type switches.
