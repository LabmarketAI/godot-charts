using System;
using System.Collections.Generic;
using Godot;
using GDArray = Godot.Collections.Array;

namespace GodotCharts;

/// <summary>
/// A 3D quantum circuit chart for VR.
///
/// Renders a <see cref="CircuitGraph"/> (loaded by <see cref="CircuitLoader"/>) as a
/// 3D scene: one horizontal wire per qubit, gate boxes at the correct layer positions,
/// and vertical connectors between multi-qubit gates.
///
/// <b>Basic usage</b>
/// <code>
/// var circuit = CircuitLoader.LoadFromFile("res://data/circuit.json");
/// var chart = new CircuitChart3D { Circuit = circuit };
/// AddChild(chart);
/// </code>
///
/// <b>Timeline scrubbing</b>: call <see cref="ShowLayer"/> to highlight a specific layer.
/// </summary>
[Tool]
public partial class CircuitChart3D : Chart3D
{
    // -------------------------------------------------------------------------
    // Exported / settable properties
    // -------------------------------------------------------------------------

    private CircuitGraph? _circuit;

    /// <summary>The circuit to render. Assigning triggers a rebuild.</summary>
    public CircuitGraph? Circuit
    {
        get => _circuit;
        set { _circuit = value; QueueRebuild(); }
    }

    private float _qubitSpacing = 0.6f;
    [Export(PropertyHint.Range, "0.2,3.0,0.05")]
    public float QubitSpacing
    {
        get => _qubitSpacing;
        set { _qubitSpacing = value; QueueRebuild(); }
    }

    private float _layerSpacing = 0.8f;
    [Export(PropertyHint.Range, "0.2,3.0,0.05")]
    public float LayerSpacing
    {
        get => _layerSpacing;
        set { _layerSpacing = value; QueueRebuild(); }
    }

    private float _wireRadius = 0.015f;
    [Export(PropertyHint.Range, "0.005,0.1,0.005")]
    public float WireRadius
    {
        get => _wireRadius;
        set { _wireRadius = value; QueueRebuild(); }
    }

    private float _gateSize = 0.3f;
    [Export(PropertyHint.Range, "0.1,1.0,0.05")]
    public float GateSize
    {
        get => _gateSize;
        set { _gateSize = value; QueueRebuild(); }
    }

    private string _circuitFilePath = "";
    [Export(PropertyHint.File, "*.json")]
    public string CircuitFilePath
    {
        get => _circuitFilePath;
        set
        {
            _circuitFilePath = value;
            if (!string.IsNullOrEmpty(value))
            {
                _circuit = CircuitLoader.LoadFromFile(value);
                QueueRebuild();
            }
        }
    }

    // -------------------------------------------------------------------------
    // Gate node tracking (for ShowLayer)
    // -------------------------------------------------------------------------

    private readonly List<(Node3D node, int layer)> _gateNodes = new();

    // -------------------------------------------------------------------------
    // Override
    // -------------------------------------------------------------------------

    protected override void _Rebuild()
    {
        Clear();
        _gateNodes.Clear();
        if (_container == null || !IsInstanceValid(_container)) return;
        if (_circuit == null) { DrawDemo(); return; }

        int numQubits = _circuit.NumQubits;
        int numLayers = _circuit.Layers.Count;
        if (numQubits == 0) return;

        float totalLength = numLayers * _layerSpacing + _layerSpacing;

        // ---- Draw qubit wires ----
        for (int q = 0; q < numQubits; q++)
        {
            float y = q * _qubitSpacing;
            var wire = DrawWire(totalLength, y);
            _container.AddChild(wire);

            // Qubit index label at left
            if (ShowLabels)
                _container.AddChild(MakeLabel($"q{q}", new Vector3(-0.4f, y, 0f), 40));
        }

        // ---- Draw gates ----
        foreach (var op in _circuit.AllOps)
        {
            float x = (op.Layer + 0.5f) * _layerSpacing;
            var gateNode = op.Qubits.Length >= 2
                ? DrawMultiQubitGate(op, x)
                : DrawSingleQubitGate(op, x);
            _container.AddChild(gateNode);
            _gateNodes.Add((gateNode, op.Layer));
        }

        // ---- Axis labels ----
        DrawAxes(totalLength, (numQubits - 1) * _qubitSpacing + _qubitSpacing * 0.5f, 0f);
        EmitSignal(SignalName.DataChanged);
    }

    /// <summary>
    /// Dim all gates except those at layer <paramref name="t"/>.
    /// Pass -1 to show all layers at full opacity.
    /// </summary>
    public void ShowLayer(int t)
    {
        foreach (var (node, layer) in _gateNodes)
            if (node is MeshInstance3D mi)
            {
                float alpha = t < 0 || layer == t ? 1f : 0.15f;
                if (mi.MaterialOverride is StandardMaterial3D mat)
                    mat.AlbedoColor = new Color(mat.AlbedoColor, alpha);
            }
    }

    // -------------------------------------------------------------------------
    // Private drawing helpers
    // -------------------------------------------------------------------------

    private MeshInstance3D DrawWire(float length, float y)
    {
        var cyl = new CylinderMesh
        {
            Height        = length,
            TopRadius     = _wireRadius,
            BottomRadius  = _wireRadius,
        };
        var mat = CreateUnshadedMaterial(new Color(0.7f, 0.7f, 0.75f));
        return new MeshInstance3D
        {
            Mesh             = cyl,
            MaterialOverride = mat,
            // CylinderMesh is Y-up; rotate 90° around Z to make it X-axis (horizontal wire)
            Basis            = new Basis(Vector3.Forward, MathF.PI * 0.5f),
            Position         = new Vector3(length * 0.5f, y, 0f),
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        };
    }

    private Node3D DrawSingleQubitGate(QuantumOp op, float x)
    {
        float y = op.Qubits[0] * _qubitSpacing;
        var color = GateColor(op.Gate);
        var mat   = new StandardMaterial3D { AlbedoColor = color };
        var box   = new BoxMesh { Size = new Vector3(_gateSize, _gateSize, _gateSize * 0.4f) };
        var mi    = new MeshInstance3D
        {
            Mesh             = box,
            MaterialOverride = mat,
            Position         = new Vector3(x, y, 0f),
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        };

        // Gate label
        var root = new Node3D { Position = new Vector3(x, y, 0f) };
        mi.Position = Vector3.Zero;
        root.AddChild(mi);
        root.AddChild(MakeLabel(op.Gate.ToUpper(), new Vector3(0f, 0f, _gateSize * 0.25f), 36));
        return root;
    }

    private Node3D DrawMultiQubitGate(QuantumOp op, float x)
    {
        var root = new Node3D();

        // Control qubit: solid sphere
        float y0 = op.Qubits[0] * _qubitSpacing;
        var ctrlMat  = new StandardMaterial3D { AlbedoColor = GateColor(op.Gate) };
        var ctrlMesh = new SphereMesh { Radius = _gateSize * 0.35f, Height = _gateSize * 0.7f };
        root.AddChild(new MeshInstance3D
        {
            Mesh             = ctrlMesh,
            MaterialOverride = ctrlMat,
            Position         = new Vector3(x, y0, 0f),
            CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
        });

        // Target qubits: box gate
        for (int i = 1; i < op.Qubits.Length; i++)
        {
            float y1 = op.Qubits[i] * _qubitSpacing;
            var tgtMat = new StandardMaterial3D { AlbedoColor = GateColor(op.Gate) };
            var box    = new BoxMesh { Size = new Vector3(_gateSize, _gateSize, _gateSize * 0.4f) };
            root.AddChild(new MeshInstance3D
            {
                Mesh             = box,
                MaterialOverride = tgtMat,
                Position         = new Vector3(x, y1, 0f),
                CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
            });

            // Vertical connector between control and target
            float dist = MathF.Abs(y1 - y0);
            if (dist > 0.001f)
            {
                var cyl = new CylinderMesh { Height = dist, TopRadius = _wireRadius * 1.5f, BottomRadius = _wireRadius * 1.5f };
                var connMat = new StandardMaterial3D { AlbedoColor = new Color(0.5f, 0.5f, 0.55f) };
                root.AddChild(new MeshInstance3D
                {
                    Mesh             = cyl,
                    MaterialOverride = connMat,
                    Position         = new Vector3(x, (y0 + y1) * 0.5f, 0f),
                    CastShadow       = GeometryInstance3D.ShadowCastingSetting.Off,
                });
            }
        }

        // Gate label
        root.AddChild(MakeLabel(op.Gate.ToUpper(), new Vector3(x, y0 + _gateSize * 0.55f, 0f), 32));
        return root;
    }

    private static Color GateColor(string gate) => gate.ToLower() switch
    {
        "h"   => new Color(0.204f, 0.596f, 1.000f),   // blue
        "x"   => new Color(1.000f, 0.408f, 0.216f),   // orange
        "y"   => new Color(0.216f, 0.784f, 0.408f),   // green
        "z"   => new Color(0.608f, 0.243f, 0.906f),   // purple
        "cx"  => new Color(0.988f, 0.729f, 0.012f),   // yellow
        "cz"  => new Color(0.976f, 0.341f, 0.573f),   // pink
        "s"   => new Color(0.0f,   0.8f,   0.8f),     // cyan
        "t"   => new Color(0.9f,   0.5f,   0.0f),     // amber
        "rx"  or "ry" or "rz" => new Color(0.6f, 0.8f, 0.6f), // light green
        _     => new Color(0.55f, 0.55f, 0.55f),      // grey for unknown
    };

    // -------------------------------------------------------------------------
    // Demo
    // -------------------------------------------------------------------------

    private void DrawDemo()
    {
        // Build a 3-qubit demo circuit: H, CX, CX
        _circuit = new CircuitGraph(
            NumQubits: 3,
            Layers: new[]
            {
                new QuantumLayer(0, new[] { new QuantumOp("n0", "h",  new[]{0},   new int[]{}, new float[]{}, 0) }),
                new QuantumLayer(1, new[] { new QuantumOp("n1", "cx", new[]{0,1}, new int[]{}, new float[]{}, 1) }),
                new QuantumLayer(2, new[] { new QuantumOp("n2", "cx", new[]{1,2}, new int[]{}, new float[]{}, 2) }),
            },
            AllOps: new[]
            {
                new QuantumOp("n0", "h",  new[]{0},   new int[]{}, new float[]{}, 0),
                new QuantumOp("n1", "cx", new[]{0,1}, new int[]{}, new float[]{}, 1),
                new QuantumOp("n2", "cx", new[]{1,2}, new int[]{}, new float[]{}, 2),
            });
        _Rebuild();
    }
}
