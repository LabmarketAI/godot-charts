using System.Collections.Generic;
using System.Text.Json.Nodes;

namespace GodotCharts;

/// <summary>
/// Typed descriptor produced by importing a widget tree JSON asset.
/// Runtime code converts these into actual Godot nodes.
/// </summary>
public sealed class WidgetNodeDescriptor
{
    public string Type { get; set; } = "";
    public float[]? Size { get; set; }
    public bool Enabled { get; set; } = true;
    public string? Text { get; set; }
    public float? Value { get; set; }
    public string? Theme { get; set; }
    public List<WidgetNodeDescriptor> Children { get; set; } = new();
}

/// <summary>
/// Typed descriptor produced by importing a theme token JSON asset.
/// Runtime code applies these to a WidgetThemeData3D resource.
/// </summary>
public sealed class ThemeDescriptor
{
    public string Id { get; set; } = "";
    public Dictionary<string, string> Colors { get; set; } = new();
    public Dictionary<string, float> Sizes { get; set; } = new();
}

/// <summary>
/// Converts validated widget schema JSON into typed descriptor objects.
/// Always validate with <see cref="WidgetSchemaValidator"/> before importing.
/// </summary>
public static class WidgetSchemaImporter
{
    /// <summary>
    /// Parses a widget tree JSON string into a <see cref="WidgetNodeDescriptor"/> tree.
    /// Returns null if the JSON is structurally unparseable; callers should validate first.
    /// </summary>
    public static WidgetNodeDescriptor? ImportWidgetTree(string json)
    {
        JsonNode? root;
        try { root = JsonNode.Parse(json); }
        catch { return null; }

        if (root is not JsonObject obj) return null;
        return ParseNode(obj);
    }

    /// <summary>
    /// Parses a theme token JSON string into a <see cref="ThemeDescriptor"/>.
    /// Returns null if the JSON is structurally unparseable; callers should validate first.
    /// </summary>
    public static ThemeDescriptor? ImportTheme(string json)
    {
        JsonNode? root;
        try { root = JsonNode.Parse(json); }
        catch { return null; }

        if (root is not JsonObject obj) return null;

        var desc = new ThemeDescriptor
        {
            Id = obj["id"]?.GetValue<string>() ?? ""
        };

        if (obj["colors"] is JsonObject colors)
        {
            foreach (var kv in colors)
            {
                var s = "";
                try { s = kv.Value?.GetValue<string>() ?? ""; } catch { }
                desc.Colors[kv.Key] = s;
            }
        }

        if (obj["sizes"] is JsonObject sizes)
        {
            foreach (var kv in sizes)
            {
                if (TryGetFloat(kv.Value, out var f))
                    desc.Sizes[kv.Key] = f;
            }
        }

        return desc;
    }

    // ── internal ──────────────────────────────────────────────────────────────

    static WidgetNodeDescriptor ParseNode(JsonObject obj)
    {
        var desc = new WidgetNodeDescriptor
        {
            Type = GetString(obj, "type"),
            Text = obj.ContainsKey("text") ? GetString(obj, "text") : null,
            Theme = obj.ContainsKey("theme") ? GetString(obj, "theme") : null,
            Enabled = obj.ContainsKey("enabled") ? (GetBool(obj, "enabled") ?? true) : true,
        };

        if (obj["size"] is JsonArray size && size.Count == 2
            && TryGetFloat(size[0], out var sx) && TryGetFloat(size[1], out var sy))
        {
            desc.Size = [sx, sy];
        }

        if (obj.ContainsKey("value") && TryGetFloat(obj["value"], out var val))
            desc.Value = val;

        if (obj["children"] is JsonArray children)
        {
            foreach (var child in children)
            {
                if (child is JsonObject childObj)
                    desc.Children.Add(ParseNode(childObj));
            }
        }

        return desc;
    }

    static string GetString(JsonObject obj, string key)
    {
        try { return obj[key]?.GetValue<string>() ?? ""; }
        catch { return ""; }
    }

    static bool? GetBool(JsonObject obj, string key)
    {
        try { return obj[key]?.GetValue<bool>(); }
        catch { return null; }
    }

    static bool TryGetFloat(JsonNode? node, out float value)
    {
        value = 0f;
        if (node is not JsonValue v) return false;
        if (v.TryGetValue<float>(out value)) return true;
        if (v.TryGetValue<int>(out var i)) { value = i; return true; }
        if (v.TryGetValue<double>(out var d)) { value = (float)d; return true; }
        return false;
    }
}
