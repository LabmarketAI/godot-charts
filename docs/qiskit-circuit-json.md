# Qiskit Circuit JSON Contract (Issue #36)

This document defines the JSON contract consumed by `CircuitLoader`.

## Supported payload shapes

### 1) Layered format (preferred)

```json
{
  "qubits": 3,
  "layers": [
    {
      "t": 0,
      "ops": [
        { "id": "n0", "gate": "h", "q": [0], "c": [], "params": [] }
      ]
    }
  ]
}
```

### 2) Flat operations with explicit DAG edges (fallback)

```json
{
  "qubits": 2,
  "ops": [
    { "id": "a", "gate": "h", "q": [0] },
    { "id": "b", "gate": "cx", "q": [0,1] }
  ],
  "edges": [
    { "from": "a", "to": "b" }
  ]
}
```

If `edges` are absent, dependencies are inferred by qubit-touch order.

## Field definitions

- `qubits` (int): total qubit count
- `layers` (array): layered operations (optional if `ops` is present)
- `layers[].t` (int): hint layer index (final layer is recomputed)
- `layers[].ops` (array): operation list
- `ops` (array): flat operation list (fallback payload)
- `edges` (array): optional explicit dependencies for flat `ops`
- `id` (string): operation id (generated as `opN` if missing)
- `gate` (string): gate/op name (`h`, `cx`, `cp`, `swap`, `measure`, etc.)
- `q` (int[]): qubit indices
- `c` (int[]): classical bit indices
- `params` (number[]): gate parameters

## Validation expectations

- Real Qiskit fixtures are stored in `tests/Fixtures/`
- Compatibility tests validate:
  - operation count
  - qubit fidelity
  - dependency/layer monotonicity
