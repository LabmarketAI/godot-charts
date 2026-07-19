using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace GodotCharts;

public sealed class ValidationResult
{
    public bool IsValid => Errors.Count == 0;
    public List<string> Errors { get; } = new();
}

public static class WidgetSchemaValidator
{
    static readonly HashSet<string> KnownWidgetTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "widget_panel", "row", "column", "grid", "stack",
        "button", "label", "toggle", "slider", "list_item"
    };

    static readonly HashSet<string> KnownColorTokens = new()
    {
        "bg_normal", "bg_hover", "bg_pressed", "bg_disabled", "bg_checked",
        "border_normal", "border_focused",
        "text_normal", "text_disabled",
        "accent", "slider_track", "slider_thumb"
    };

    static readonly HashSet<string> KnownSizeTokens = new()
    {
        "text_size", "border_width"
    };

    public static ValidationResult ValidateWidgetTree(string json)
    {
        var result = new ValidationResult();
        JsonNode? root;
        try { root = JsonNode.Parse(json); }
        catch (JsonException ex) { result.Errors.Add($"Invalid JSON: {ex.Message}"); return result; }

        if (root is not JsonObject obj)
        {
            result.Errors.Add("Root must be a JSON object.");
            return result;
        }

        if (!obj.ContainsKey("schema_version"))
            result.Errors.Add("$.schema_version: required field missing.");

        ValidateWidgetNode(obj, "$", result);
        return result;
    }

    public static ValidationResult ValidateTheme(string json)
    {
        var result = new ValidationResult();
        JsonNode? root;
        try { root = JsonNode.Parse(json); }
        catch (JsonException ex) { result.Errors.Add($"Invalid JSON: {ex.Message}"); return result; }

        if (root is not JsonObject obj)
        {
            result.Errors.Add("Root must be a JSON object.");
            return result;
        }

        if (!obj.ContainsKey("schema_version"))
            result.Errors.Add("$.schema_version: required field missing.");

        if (!obj.ContainsKey("id") || string.IsNullOrWhiteSpace(obj["id"]?.GetValue<string>()))
            result.Errors.Add("$.id: required field missing or empty.");

        if (!obj.ContainsKey("colors"))
        {
            result.Errors.Add("$.colors: required field missing.");
        }
        else if (obj["colors"] is JsonObject colors)
        {
            foreach (var kv in colors)
            {
                if (!KnownColorTokens.Contains(kv.Key))
                    result.Errors.Add($"$.colors.{kv.Key}: unknown color token.");
                else if (!IsValidHexColor(kv.Value?.GetValue<string>() ?? ""))
                    result.Errors.Add($"$.colors.{kv.Key}: expected a hex color string (e.g. \"#RRGGBB\").");
            }
        }
        else
        {
            result.Errors.Add("$.colors: expected an object.");
        }

        if (!obj.ContainsKey("sizes"))
        {
            result.Errors.Add("$.sizes: required field missing.");
        }
        else if (obj["sizes"] is JsonObject sizes)
        {
            foreach (var kv in sizes)
            {
                if (!KnownSizeTokens.Contains(kv.Key))
                    result.Errors.Add($"$.sizes.{kv.Key}: unknown size token.");
            }
            if (sizes.ContainsKey("text_size"))
            {
                if (!TryGetPositiveInt(sizes["text_size"], out _))
                    result.Errors.Add("$.sizes.text_size: expected a positive integer.");
            }
            if (sizes.ContainsKey("border_width"))
            {
                if (!TryGetPositiveFloat(sizes["border_width"], out _))
                    result.Errors.Add("$.sizes.border_width: expected a positive number.");
            }
        }
        else
        {
            result.Errors.Add("$.sizes: expected an object.");
        }

        return result;
    }

    // ── internal ──────────────────────────────────────────────────────────────

    static void ValidateWidgetNode(JsonObject node, string path, ValidationResult result)
    {
        if (!node.ContainsKey("type"))
        {
            result.Errors.Add($"{path}.type: required field missing.");
            return;
        }

        var type = "";
        try { type = node["type"]!.GetValue<string>(); }
        catch { result.Errors.Add($"{path}.type: expected a string."); return; }

        if (!KnownWidgetTypes.Contains(type))
            result.Errors.Add($"{path}.type: unknown widget type \"{type}\".");

        if (node.ContainsKey("size"))
            ValidateSize(node["size"], path, result);

        if (node.ContainsKey("enabled"))
        {
            bool ok = false;
            try { node["enabled"]!.GetValue<bool>(); ok = true; } catch { }
            if (!ok) result.Errors.Add($"{path}.enabled: expected a boolean.");
        }

        if (node.ContainsKey("text"))
        {
            bool ok = false;
            try { node["text"]!.GetValue<string>(); ok = true; } catch { }
            if (!ok) result.Errors.Add($"{path}.text: expected a string.");
        }

        if (node.ContainsKey("value"))
        {
            if (!TryGetFloat(node["value"], out _))
                result.Errors.Add($"{path}.value: expected a number.");
        }

        if (node.ContainsKey("children"))
        {
            if (node["children"] is not JsonArray children)
            {
                result.Errors.Add($"{path}.children: expected an array.");
            }
            else
            {
                for (int i = 0; i < children.Count; i++)
                {
                    if (children[i] is JsonObject child)
                        ValidateWidgetNode(child, $"{path}.children[{i}]", result);
                    else
                        result.Errors.Add($"{path}.children[{i}]: expected an object.");
                }
            }
        }
    }

    static void ValidateSize(JsonNode? size, string path, ValidationResult result)
    {
        if (size is not JsonArray arr || arr.Count != 2)
        {
            result.Errors.Add($"{path}.size: expected an array of exactly two numbers.");
            return;
        }
        for (int i = 0; i < 2; i++)
        {
            if (!TryGetPositiveFloat(arr[i], out _))
                result.Errors.Add($"{path}.size[{i}]: expected a positive number.");
        }
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

    static bool TryGetPositiveFloat(JsonNode? node, out float value) =>
        TryGetFloat(node, out value) && value > 0f;

    static bool TryGetPositiveInt(JsonNode? node, out int value)
    {
        value = 0;
        if (node is not JsonValue v) return false;
        if (v.TryGetValue<int>(out value)) return value > 0;
        if (v.TryGetValue<float>(out var f) && f == MathF.Floor(f)) { value = (int)f; return value > 0; }
        return false;
    }

    static bool IsValidHexColor(string s)
    {
        if (string.IsNullOrEmpty(s) || s[0] != '#') return false;
        var hex = s[1..];
        return (hex.Length == 6 || hex.Length == 8) && hex.All(IsHexChar);
    }

    static bool IsHexChar(char c) =>
        (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}
