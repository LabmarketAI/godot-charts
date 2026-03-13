using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Godot;
using GDArray = Godot.Collections.Array;
using GDDict = Godot.Collections.Dictionary;

namespace GodotCharts;

/// <summary>
/// A <see cref="ChartDataSource"/> that holds a graph network (nodes + edges).
///
/// Supports loading from a JSON file or an inline dictionary. The JSON
/// format is compatible with NetworkX / iGraph node_link_data exports:
/// <code>
/// {
///   "nodes": [
///     { "id": "A", "label": "Alice", "type": "person",
///       "x": 0.2, "y": 0.8, "z": 0.0 }
///   ],
///   "edges": [
///     { "source": "A", "target": "B", "label": "knows",
///       "weight": 1.0, "directed": false }
///   ]
/// }
/// </code>
///
/// <b>Mutation API</b> — call <see cref="AddNode"/>, <see cref="RemoveNode"/>,
/// <see cref="AddEdge"/>, <see cref="RemoveEdge"/> to modify the graph at runtime;
/// each emits <see cref="ChartDataSource.DataUpdated"/> automatically.
///
/// <b>Hot-reload</b> — set <see cref="WatchFile"/> = <c>true</c>.
/// Uses <see cref="FileSystemWatcher"/> internally; call <see cref="Tick"/>
/// from the chart's <c>_Process</c> to apply any pending reload on the main thread.
/// </summary>
[Tool]
public partial class GraphNetworkDataSource : ChartDataSource
{
    private string _filePath = "";

    [Export(PropertyHint.File, "*.json")]
    public string FilePath
    {
        get => _filePath;
        set
        {
            _filePath = value;
            if (!string.IsNullOrEmpty(value))
                LoadFromFile(value);
        }
    }

    private bool _watchFile;

    /// <summary>
    /// When <c>true</c>, a <see cref="FileSystemWatcher"/> monitors the file for changes.
    /// Call <see cref="Tick"/> from the chart's <c>_Process</c> to apply reloads on the main thread.
    /// </summary>
    [Export]
    public bool WatchFile
    {
        get => _watchFile;
        set
        {
            _watchFile = value;
            UpdateWatcher();
        }
    }

    // ---- internal state ----
    private GDArray _nodes = new();  // Array of GDDict
    private GDArray _edges = new();  // Array of GDDict
    private readonly Dictionary<string, int> _nodeMap = new();  // id -> index

    private FileSystemWatcher? _watcher;
    private volatile bool _reloadPending;

    // -------------------------------------------------------------------------
    // Public API — data loading
    // -------------------------------------------------------------------------

    /// <summary>
    /// Replace the current graph with <paramref name="d"/>
    /// (<c>{ "nodes": [...], "edges": [...] }</c>).
    /// Emits <see cref="ChartDataSource.DataUpdated"/>.
    /// </summary>
    public void LoadFromDict(GDDict d)
    {
        _nodes = d.TryGetValue("nodes", out Variant nv) && nv.Obj is GDArray na
            ? (GDArray)na.Duplicate(true)
            : new GDArray();
        _edges = d.TryGetValue("edges", out Variant ev) && ev.Obj is GDArray ea
            ? (GDArray)ea.Duplicate(true)
            : d.TryGetValue("links", out Variant lv) && lv.Obj is GDArray la
                ? (GDArray)la.Duplicate(true)
            : new GDArray();
        RebuildIndex();
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>
    /// Load a JSON file from <paramref name="path"/> and replace the current graph.
    /// Returns <c>true</c> on success. Accepts <c>res://</c> paths and absolute paths.
    /// </summary>
    public bool LoadFromFile(string path)
    {
        string absPath = path.StartsWith("res://") || path.StartsWith("user://")
            ? ProjectSettings.GlobalizePath(path)
            : path;

        if (!File.Exists(absPath))
        {
            GD.PushWarning($"GraphNetworkDataSource: file not found — {path}");
            return false;
        }

        string text;
        try { text = File.ReadAllText(absPath); }
        catch (Exception ex)
        {
            GD.PushWarning($"GraphNetworkDataSource: cannot read — {path}: {ex.Message}");
            return false;
        }

        JsonDocument doc;
        try { doc = JsonDocument.Parse(text); }
        catch (JsonException ex)
        {
            GD.PushWarning($"GraphNetworkDataSource: invalid JSON in — {path}: {ex.Message}");
            return false;
        }

        using (doc)
        {
            if (doc.RootElement.ValueKind != JsonValueKind.Object)
            {
                GD.PushWarning($"GraphNetworkDataSource: JSON root is not an object — {path}");
                return false;
            }
            var gd = (GDDict)JsonElementToVariant(doc.RootElement);
            LoadFromDict(gd);
        }

        return true;
    }

    /// <summary>Serialise the current node/edge state to <paramref name="path"/> as JSON.</summary>
    public bool SaveToJson(string path)
    {
        string absPath = path.StartsWith("res://") || path.StartsWith("user://")
            ? ProjectSettings.GlobalizePath(path)
            : path;

        try
        {
            var data = GetData();
            // Convert Godot dict to a plain object for JSON serialisation
            string json = JsonSerializer.Serialize(GodotDictToObject(data), new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(absPath, json);
            return true;
        }
        catch (Exception ex)
        {
            GD.PushWarning($"GraphNetworkDataSource: cannot write — {path}: {ex.Message}");
            return false;
        }
    }

    // -------------------------------------------------------------------------
    // Public API — mutation
    // -------------------------------------------------------------------------

    /// <summary>
    /// Add or replace a node. <paramref name="props"/> may contain any keys;
    /// <c>"id"</c> is always overwritten with <paramref name="id"/>.
    /// </summary>
    public void AddNode(string id, GDDict? props = null)
    {
        var entry = props != null ? (GDDict)props.Duplicate() : new GDDict();
        entry["id"] = id;
        if (_nodeMap.TryGetValue(id, out int idx))
            _nodes[idx] = entry;
        else
        {
            _nodeMap[id] = _nodes.Count;
            _nodes.Add(entry);
        }
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>Remove the node with <paramref name="id"/> and all edges incident to it.</summary>
    public void RemoveNode(string id)
    {
        if (!_nodeMap.ContainsKey(id)) return;
        int idx = _nodeMap[id];
        _nodes.RemoveAt(idx);
        for (int i = _edges.Count - 1; i >= 0; i--)
        {
            var e = (GDDict)_edges[i];
            if ((string)e.GetValueOrDefault("source", "") == id ||
                (string)e.GetValueOrDefault("target", "") == id)
                _edges.RemoveAt(i);
        }
        RebuildIndex();
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>
    /// Add an edge from <paramref name="source"/> to <paramref name="target"/>.
    /// <paramref name="props"/> may include <c>"label"</c>, <c>"weight"</c>, <c>"directed"</c>, etc.
    /// </summary>
    public void AddEdge(string source, string target, GDDict? props = null)
    {
        var entry = props != null ? (GDDict)props.Duplicate() : new GDDict();
        entry["source"] = source;
        entry["target"] = target;
        _edges.Add(entry);
        EmitSignal(SignalName.DataUpdated, GetData());
    }

    /// <summary>Remove the first edge matching <paramref name="source"/> → <paramref name="target"/>.</summary>
    public void RemoveEdge(string source, string target)
    {
        for (int i = 0; i < _edges.Count; i++)
        {
            var e = (GDDict)_edges[i];
            if ((string)e.GetValueOrDefault("source", "") == source &&
                (string)e.GetValueOrDefault("target", "") == target)
            {
                _edges.RemoveAt(i);
                EmitSignal(SignalName.DataUpdated, GetData());
                return;
            }
        }
    }

    // -------------------------------------------------------------------------
    // ChartDataSource interface
    // -------------------------------------------------------------------------

    public override GDDict GetData() => new GDDict
    {
        { "nodes", (GDArray)_nodes.Duplicate(true) },
        { "edges", (GDArray)_edges.Duplicate(true) },
    };

    // -------------------------------------------------------------------------
    // Hot-reload — called by GraphNetworkChart3D from _Process
    // -------------------------------------------------------------------------

    /// <summary>
    /// Apply any pending file reload triggered by <see cref="FileSystemWatcher"/>.
    /// Call this once per frame from the chart's <c>_Process</c>.
    /// </summary>
    public void Tick()
    {
        if (!_reloadPending) return;
        _reloadPending = false;
        if (!string.IsNullOrEmpty(_filePath))
            LoadFromFile(_filePath);
    }

    // -------------------------------------------------------------------------
    // Watcher management
    // -------------------------------------------------------------------------

    private void UpdateWatcher()
    {
        _watcher?.Dispose();
        _watcher = null;
        if (!_watchFile || string.IsNullOrEmpty(_filePath)) return;

        string absPath = _filePath.StartsWith("res://") || _filePath.StartsWith("user://")
            ? ProjectSettings.GlobalizePath(_filePath)
            : _filePath;

        if (!File.Exists(absPath)) return;

        _watcher = new FileSystemWatcher(Path.GetDirectoryName(absPath)!, Path.GetFileName(absPath))
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size,
            EnableRaisingEvents = true,
        };
        _watcher.Changed += (_, _) => _reloadPending = true;
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    private void RebuildIndex()
    {
        _nodeMap.Clear();
        for (int i = 0; i < _nodes.Count; i++)
        {
            if (_nodes[i].Obj is GDDict n && n.TryGetValue("id", out Variant idVar))
                _nodeMap[idVar.ToString()] = i;
        }
    }

    /// <summary>Recursively convert a <see cref="JsonElement"/> to a Godot Variant.</summary>
    private static Variant JsonElementToVariant(JsonElement el)
    {
        switch (el.ValueKind)
        {
            case JsonValueKind.Object:
                var dict = new GDDict();
                foreach (var prop in el.EnumerateObject())
                    dict[prop.Name] = JsonElementToVariant(prop.Value);
                return dict;

            case JsonValueKind.Array:
                var arr = new GDArray();
                foreach (var item in el.EnumerateArray())
                    arr.Add(JsonElementToVariant(item));
                return arr;

            case JsonValueKind.String:
                return el.GetString() ?? "";

            case JsonValueKind.Number:
                return el.TryGetInt64(out long l) ? (double)l : el.GetDouble();

            case JsonValueKind.True:
                return true;

            case JsonValueKind.False:
                return false;

            default:
                return default;
        }
    }

    /// <summary>Recursively convert a Godot Variant to a plain .NET object for JSON serialisation.</summary>
    private static object? GodotDictToObject(Variant v)
    {
        if (v.Obj is GDDict d)
        {
            var obj = new System.Collections.Generic.Dictionary<string, object?>();
            foreach (Variant key in d.Keys)
                obj[key.ToString()] = GodotDictToObject(d[key]);
            return obj;
        }
        if (v.Obj is GDArray a)
        {
            var list = new List<object?>();
            foreach (Variant item in a)
                list.Add(GodotDictToObject(item));
            return list;
        }
        // Primitive types
        return v.VariantType switch
        {
            Variant.Type.Bool   => (bool)v,
            Variant.Type.Int    => (long)v,
            Variant.Type.Float  => (double)v,
            Variant.Type.String => v.ToString(),
            _                   => v.ToString(),
        };
    }
}
