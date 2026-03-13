using System.Collections.Generic;

namespace GodotCharts;

/// <summary>
/// A single quantum operation (gate) in a circuit.
/// </summary>
public record QuantumOp(
    string Id,
    string Gate,
    int[]  Qubits,
    int[]  Cbits,
    float[] Params,
    int    Layer   // assigned by CircuitLoader topology sort
);

/// <summary>
/// One time-step column of simultaneous gates.
/// </summary>
public record QuantumLayer(int T, IReadOnlyList<QuantumOp> Ops);

/// <summary>
/// Fully resolved circuit: qubit count, layers in time order, all ops.
/// </summary>
public record CircuitGraph(
    int                    NumQubits,
    IReadOnlyList<QuantumLayer> Layers,
    IReadOnlyList<QuantumOp>   AllOps
);
