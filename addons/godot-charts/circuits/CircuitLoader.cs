using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using Godot;
using QuikGraph;
using QuikGraph.Algorithms;

namespace GodotCharts;

/// <summary>
/// Parses a Qiskit-compatible circuit JSON file into a <see cref="CircuitGraph"/>.
///
/// <b>JSON format</b>
/// <code>
/// {
///   "qubits": 5,
///   "layers": [
///     {"t": 0, "ops": [{"id":"n0","gate":"h","q":[0],"c":[],"params":[]}]},
///     {"t": 1, "ops": [{"id":"n1","gate":"cx","q":[0,1],"c":[],"params":[]}]}
///   ]
/// }
/// </code>
///
/// The <c>t</c> field is an optional hint; QuikGraph topological sort is authoritative.
/// </summary>
public static class CircuitLoader
{
    /// <summary>
    /// Load a circuit from a JSON file.
    /// Accepts <c>res://</c> paths and absolute paths.
    /// Returns null and logs a warning on failure.
    /// </summary>
    public static CircuitGraph? LoadFromFile(string path)
    {
        string absPath = path.StartsWith("res://") || path.StartsWith("user://")
            ? ProjectSettings.GlobalizePath(path)
            : path;

        if (!File.Exists(absPath))
        {
            GD.PushWarning($"CircuitLoader: file not found — {path}");
            return null;
        }

        string text;
        try { text = File.ReadAllText(absPath); }
        catch (Exception ex)
        {
            GD.PushWarning($"CircuitLoader: cannot read — {path}: {ex.Message}");
            return null;
        }

        return Parse(text);
    }

    /// <summary>Parse circuit JSON from a string.</summary>
    public static CircuitGraph? Parse(string json)
    {
        JsonDocument doc;
        try { doc = JsonDocument.Parse(json); }
        catch (JsonException ex)
        {
            GD.PushWarning($"CircuitLoader: invalid JSON: {ex.Message}");
            return null;
        }

        using (doc)
        {
            var root = doc.RootElement;
            int numQubits = root.TryGetProperty("qubits", out var qp) ? qp.GetInt32() : 1;

            // ---- Parse raw ops from layers ----
            var rawOps = new List<(string id, string gate, int[] q, int[] c, float[] p, int hintT)>();
            if (root.TryGetProperty("layers", out var layersEl))
                foreach (var layer in layersEl.EnumerateArray())
                {
                    int hintT = layer.TryGetProperty("t", out var tp) ? tp.GetInt32() : 0;
                    if (!layer.TryGetProperty("ops", out var opsEl)) continue;
                    foreach (var op in opsEl.EnumerateArray())
                    {
                        string id    = op.TryGetProperty("id",     out var idp)     ? idp.GetString() ?? "" : "";
                        string gate  = op.TryGetProperty("gate",   out var gatep)   ? gatep.GetString() ?? "u" : "u";
                        int[]  qb    = ParseIntArray(op, "q");
                        int[]  cb    = ParseIntArray(op, "c");
                        float[] prm  = ParseFloatArray(op, "params");
                        rawOps.Add((id, gate, qb, cb, prm, hintT));
                    }
                }

            // ---- Build gate-dependency DAG with QuikGraph ----
            // Two gates are dependent if they act on the same qubit; later gates depend on earlier.
            var graph = new AdjacencyGraph<string, Edge<string>>(allowParallelEdges: false);
            foreach (var (id, _, _, _, _, _) in rawOps)
                graph.AddVertex(id);

            // Track the last gate touching each qubit
            var lastOnQubit = new Dictionary<int, string>();
            foreach (var (id, _, qb, _, _, _) in rawOps)
                foreach (int q in qb)
                {
                    if (lastOnQubit.TryGetValue(q, out string? prev))
                        graph.AddEdge(new Edge<string>(prev, id));
                    lastOnQubit[q] = id;
                }

            // ---- Topological sort → assign layer t ----
            var layerOf = new Dictionary<string, int>();
            foreach (string id in graph.TopologicalSort())
            {
                int maxPred = -1;
                foreach (var edge in graph.Edges)
                    if (edge.Target == id && layerOf.TryGetValue(edge.Source, out int tPred))
                        maxPred = Math.Max(maxPred, tPred);
                layerOf[id] = maxPred + 1;
            }

            // ---- Build final QuantumOps ----
            var allOps = rawOps
                .Select(r => new QuantumOp(r.id, r.gate, r.q, r.c, r.p, layerOf.GetValueOrDefault(r.id, r.hintT)))
                .ToList();

            var layerGroups = allOps
                .GroupBy(op => op.Layer)
                .OrderBy(g => g.Key)
                .Select(g => new QuantumLayer(g.Key, g.ToList()))
                .ToList();

            return new CircuitGraph(numQubits, layerGroups, allOps);
        }
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private static int[] ParseIntArray(JsonElement el, string prop)
    {
        if (!el.TryGetProperty(prop, out var arr)) return Array.Empty<int>();
        return arr.EnumerateArray().Select(x => x.GetInt32()).ToArray();
    }

    private static float[] ParseFloatArray(JsonElement el, string prop)
    {
        if (!el.TryGetProperty(prop, out var arr)) return Array.Empty<float>();
        return arr.EnumerateArray().Select(x => (float)x.GetDouble()).ToArray();
    }
}
