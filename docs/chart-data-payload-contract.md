# Chart Data Payload Contract

This document defines a stable JSON payload shape for chart data publication and subscription workflows (for example, issue #8 Jupyter -> Godot routing).

## Goals

- Keep chart payloads transport-friendly (JSON).
- Keep rendering-specific state out of payloads.
- Provide enough metadata for deterministic replay and cross-client rendering.

## Envelope

All chart payloads should include a small common envelope:

```json
{
  "kind": "histogram",
  "version": "1.0",
  "source": {
    "workspace": "default",
    "topic": "notebook:foo.ipynb/cell:abc123"
  },
  "updated_at": "2026-03-19T12:00:00Z",
  "payload": {}
}
```

Fields:

- `kind`: chart kind (`histogram`, `line`, `scatter`, `bar`, `surface`, `graph_network`, `circuit`)
- `version`: payload schema version
- `source.workspace`: optional logical workspace name
- `source.topic`: stable routing key for external subscribers
- `updated_at`: UTC timestamp (ISO 8601)
- `payload`: kind-specific body

## Histogram Payload (recommended)

```json
{
  "kind": "histogram",
  "version": "1.0",
  "source": {
    "workspace": "default",
    "topic": "notebook:foo.ipynb/cell:abc123"
  },
  "updated_at": "2026-03-19T12:00:00Z",
  "payload": {
    "name": "Count",
    "bin_edges": [0.0, 1.0, 2.0, 3.0],
    "counts": [10, 7, 2],
    "binning": {
      "mode": "auto",
      "rule": "freedman_diaconis",
      "fallback": "sturges"
    }
  }
}
```

Rules:

- `bin_edges.length = counts.length + 1`
- `bin_edges` MUST be monotonic non-decreasing
- `counts` MUST be non-negative integers
- Last bin is closed on the right edge

Notes for current implementation:

- `HistogramChart3D` supports explicit `BinEdges` (manual mode).
- Auto mode uses `ChartBinner.SuggestBinCountAuto(...)`.
- Auto rule implementation is Freedman-Diaconis with Sturges fallback.

## Bar/Line/Scatter Payload Sketches

Bar/line payloads should continue to align with existing addon dictionary patterns:

```json
{
  "kind": "bar",
  "version": "1.0",
  "payload": {
    "labels": ["A", "B", "C"],
    "datasets": [
      { "name": "Series 1", "values": [1.0, 2.0, 3.0] }
    ]
  }
}
```

```json
{
  "kind": "scatter",
  "version": "1.0",
  "payload": {
    "datasets": [
      {
        "name": "Cluster A",
        "points": [
          { "x": 0.2, "y": 1.3, "z": 0.5 },
          { "x": 0.4, "y": 1.1, "z": 0.7 }
        ]
      }
    ]
  }
}
```

## Backward Compatibility

- New fields should be additive.
- Producers should keep `version` explicit.
- Consumers should ignore unknown fields.

## Integration Guidance for #8

For Jupyter routing:

- Use `source.topic` as the subscriber key (`notebook:{path}/cell:{cell_id}`).
- Keep `kind` in envelope so a mixed stream can be demultiplexed without inspecting payload internals.
- Keep payload numeric arrays compact for efficient Godot-side conversion.
