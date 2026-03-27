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
/// Parses Qiskit-compatible circuit JSON into a <see cref="CircuitGraph"/>.
///
/// Supported payload shapes:
/// 1) Layered format:
/// {
///   "qubits": 5,
///   "layers": [
///     {"t": 0, "ops": [{"id":"n0","gate":"h","q":[0],"c":[],"params":[]}]},
///     {"t": 1, "ops": [{"id":"n1","gate":"cx","q":[0,1],"c":[],"params":[]}]}
///   ]
/// }
///
/// 2) Flat ops with explicit dependency edges:
/// {
///   "qubits": 3,
///   "ops": [
///     {"id":"a","gate":"h","q":[0]},
///     {"id":"b","gate":"cx","q":[0,1]}
///   ],
///   "edges": [
///     {"from":"a","to":"b"}
///   ]
/// }
///
/// The final layer assignment is computed with QuikGraph topological sort.
/// Provided t values are hints only.
/// </summary>
public static class CircuitLoader
{
    private readonly record struct RawOp(string Id, string Gate, int[] Qubits, int[] Cbits, float[] Params, int HintLayer);

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
            GD.PushWarning($"CircuitLoader: file not found - {path}");
            return null;
        }

        string text;
        try { text = File.ReadAllText(absPath); }
        catch (Exception ex)
        {
            GD.PushWarning($"CircuitLoader: cannot read - {path}: {ex.Message}");
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
            int numQubits = ParseQubitCount(root);

            var rawOps = ParseRawOps(root);
            if (rawOps.Count == 0)
            {
                GD.PushWarning("CircuitLoader: no operations found (expected layers[].ops[] or ops[])");
                return new CircuitGraph(numQubits, new List<QuantumLayer>(), new List<QuantumOp>());
            }

            var graph = new AdjacencyGraph<string, Edge<string>>(allowParallelEdges: false);
            foreach (var op in rawOps)
                graph.AddVertex(op.Id);

            if (!TryAddExplicitEdges(root, rawOps, graph))
                AddQubitInferredEdges(rawOps, graph);

            List<string> topoOrder;
            try
            {
                topoOrder = graph.TopologicalSort().ToList();
            }
            catch (Exception ex)
            {
                GD.PushWarning($"CircuitLoader: cyclic or invalid dependency graph: {ex.Message}");
                return null;
            }

            var layerOf = new Dictionary<string, int>();
            foreach (string id in topoOrder)
            {
                int maxPred = -1;
                foreach (var edge in graph.Edges)
                    if (edge.Target == id && layerOf.TryGetValue(edge.Source, out int tPred))
                        maxPred = Math.Max(maxPred, tPred);
                layerOf[id] = maxPred + 1;
            }

            var allOps = rawOps
                .Select(r => new QuantumOp(r.Id, r.Gate, r.Qubits, r.Cbits, r.Params, layerOf.GetValueOrDefault(r.Id, r.HintLayer)))
                .OrderBy(op => op.Layer)
                .ThenBy(op => op.Id)
                .ToList();

            var layerGroups = allOps
                .GroupBy(op => op.Layer)
                .OrderBy(g => g.Key)
                .Select(g => new QuantumLayer(g.Key, g.ToList()))
                .ToList();

            return new CircuitGraph(numQubits, layerGroups, allOps);
        }
    }

    private static List<RawOp> ParseRawOps(JsonElement root)
    {
        var rawOps = new List<RawOp>();

        if (root.TryGetProperty("layers", out var layersEl))
        {
            foreach (var layer in layersEl.EnumerateArray())
            {
                int hintT = layer.TryGetProperty("t", out var tp) ? tp.GetInt32() : 0;
                if (!layer.TryGetProperty("ops", out var opsEl)) continue;
                foreach (var op in opsEl.EnumerateArray())
                    rawOps.Add(ParseOp(op, hintT, rawOps.Count));
            }
            return rawOps;
        }

        if (root.TryGetProperty("ops", out var flatOpsEl))
        {
            foreach (var op in flatOpsEl.EnumerateArray())
            {
                int hintT = op.TryGetProperty("t", out var tp) ? tp.GetInt32() : 0;
                rawOps.Add(ParseOp(op, hintT, rawOps.Count));
            }
        }

        return rawOps;
    }

    private static RawOp ParseOp(JsonElement op, int hintT, int ordinal)
    {
        string id = op.TryGetProperty("id", out var idp) ? idp.GetString() ?? string.Empty : string.Empty;
        if (string.IsNullOrWhiteSpace(id)) id = $"op{ordinal}";

        string gate = op.TryGetProperty("gate", out var gatep) ? gatep.GetString() ?? "u" : "u";
        int[] qb = ParseIntArray(op, "q", "qubits");
        int[] cb = ParseIntArray(op, "c", "cbits");
        float[] prm = ParseFloatArray(op, "params");
        return new RawOp(id, gate, qb, cb, prm, hintT);
    }

    private static bool TryAddExplicitEdges(JsonElement root, List<RawOp> rawOps, AdjacencyGraph<string, Edge<string>> graph)
    {
        if (!root.TryGetProperty("edges", out var edgesEl)) return false;

        var validIds = rawOps.Select(op => op.Id).ToHashSet();

        foreach (var edgeEl in edgesEl.EnumerateArray())
        {
            string from;
            string to;

            if (edgeEl.TryGetProperty("from", out var fromEl) && edgeEl.TryGetProperty("to", out var toEl))
            {
                from = fromEl.GetString() ?? string.Empty;
                to = toEl.GetString() ?? string.Empty;
            }
            else if (edgeEl.TryGetProperty("source", out var sourceEl) && edgeEl.TryGetProperty("target", out var targetEl))
            {
                from = sourceEl.GetString() ?? string.Empty;
                to = targetEl.GetString() ?? string.Empty;
            }
            else
            {
                continue;
            }

            if (from.Length == 0 || to.Length == 0) continue;
            if (from == to) continue;
            if (!validIds.Contains(from) || !validIds.Contains(to)) continue;

            graph.AddEdge(new Edge<string>(from, to));
        }

        if (graph.EdgeCount > 0)
            return true;

        var byId = rawOps.ToDictionary(op => op.Id);
        foreach (var op in rawOps)
        {
            if (!TryGetDepsForOp(root, byId, op.Id, out var deps))
                continue;

            foreach (var dep in deps)
            {
                if (!validIds.Contains(dep) || dep == op.Id)
                    continue;
                graph.AddEdge(new Edge<string>(dep, op.Id));
            }
        }

        return graph.EdgeCount > 0;
    }

    private static bool TryGetDepsForOp(JsonElement root, Dictionary<string, RawOp> byId, string opId, out List<string> deps)
    {
        deps = new List<string>();
        if (!root.TryGetProperty("ops", out var flatOpsEl))
            return false;

        foreach (var opEl in flatOpsEl.EnumerateArray())
        {
            var id = opEl.TryGetProperty("id", out var idEl) ? idEl.GetString() ?? string.Empty : string.Empty;
            if (!string.Equals(id, opId, StringComparison.Ordinal))
                continue;

            if (!opEl.TryGetProperty("deps", out var depsEl))
                return false;

            foreach (var depEl in depsEl.EnumerateArray())
            {
                var dep = depEl.GetString() ?? string.Empty;
                if (dep.Length == 0)
                    continue;
                if (byId.ContainsKey(dep))
                    deps.Add(dep);
            }

            return deps.Count > 0;
        }

        return false;
    }

    private static void AddQubitInferredEdges(List<RawOp> rawOps, AdjacencyGraph<string, Edge<string>> graph)
    {
        var lastOnQubit = new Dictionary<int, string>();

        foreach (var op in rawOps)
        {
            foreach (int q in op.Qubits)
            {
                if (lastOnQubit.TryGetValue(q, out string? prev))
                    graph.AddEdge(new Edge<string>(prev, op.Id));
                lastOnQubit[q] = op.Id;
            }
        }
    }

    private static int ParseQubitCount(JsonElement root)
    {
        if (root.TryGetProperty("qubits", out var qubitsProp))
        {
            if (qubitsProp.ValueKind == JsonValueKind.Number)
                return Math.Max(1, qubitsProp.GetInt32());
            if (qubitsProp.ValueKind == JsonValueKind.Array)
                return Math.Max(1, qubitsProp.GetArrayLength());
        }

        if (root.TryGetProperty("num_qubits", out var numQubitsProp) && numQubitsProp.ValueKind == JsonValueKind.Number)
            return Math.Max(1, numQubitsProp.GetInt32());

        return 1;
    }

    private static int[] ParseIntArray(JsonElement el, params string[] props)
    {
        foreach (var prop in props)
        {
            if (!el.TryGetProperty(prop, out var arr) || arr.ValueKind != JsonValueKind.Array)
                continue;
            return arr.EnumerateArray().Select(x => x.GetInt32()).ToArray();
        }

        return Array.Empty<int>();
    }

    private static float[] ParseFloatArray(JsonElement el, string prop)
    {
        if (!el.TryGetProperty(prop, out var arr)) return Array.Empty<float>();
        return arr.EnumerateArray().Select(x => (float)x.GetDouble()).ToArray();
    }
}
