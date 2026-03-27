using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace GodotCharts;

/// <summary>
/// Result of translating a component spec file.
/// </summary>
public sealed class TranslationResult
{
    /// <summary>One descriptor per successfully translated component.</summary>
    public List<WidgetNodeDescriptor> Descriptors { get; } = new();
    /// <summary>Non-fatal notices for unsupported props, events, or partial mappings.</summary>
    public List<string> Warnings { get; } = new();
    /// <summary>Fatal problems that prevented a component from being translated.</summary>
    public List<string> Errors { get; } = new();

    public bool HasWarnings => Warnings.Count > 0;
    public bool HasErrors => Errors.Count > 0;
}

/// <summary>
/// Translates a curated external component spec (source format v1) into
/// <see cref="WidgetNodeDescriptor"/> objects consumable by the runtime.
///
/// Source format: a JSON object with fields:
///   spec_version  string  required
///   source        string  optional – identifies the origin library
///   family        string  optional – component family name
///   components    array   required – list of component definition objects
///
/// Each component definition:
///   name          string  required
///   props         object  optional – prop name → prop descriptor
///   events        array   optional – event name strings
///   states        array   optional – state name strings
///
/// Prop descriptor:
///   type          string  "string" | "boolean" | "number"
///   required      bool    optional
///   default       any     optional
///   min / max     number  optional (for type=number)
///   unit          string  optional – "dp" triggers unit conversion
///   width_dp / height_dp at top level are also accepted as shorthand
///
/// Conversion rules:
///   dp → metres via DP_TO_METERS (0.001 m/dp)
///   name → widget type via TypeMap; unmapped names produce a warning + skip
///   "label"/"text" prop → WidgetNodeDescriptor.Text
///   "disabled" prop     → WidgetNodeDescriptor.Enabled (inverted)
///   "checked"/"value"   → WidgetNodeDescriptor.Value
///   events/states have no equivalent in schema v1 → warning emitted
///   unknown props       → warning emitted
/// </summary>
public static class WidgetSpecTranslator
{
    /// <summary>1 dp = 1 mm in world space.</summary>
    public const float DpToMeters = 0.001f;

    /// <summary>Default size when no width/height is specified (metres).</summary>
    public static readonly float[] DefaultSize = [0.2f, 0.08f];

    static readonly Dictionary<string, string> TypeMap =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["Button"]    = "button",
            ["Switch"]    = "toggle",
            ["Toggle"]    = "toggle",
            ["Slider"]    = "slider",
            ["Label"]     = "label",
            ["Text"]      = "label",
            ["ListItem"]  = "list_item",
            ["List_Item"] = "list_item",
            ["Row"]       = "row",
            ["Column"]    = "column",
            ["Stack"]     = "stack",
            ["Grid"]      = "grid",
            ["Panel"]     = "widget_panel",
        };

    /// <summary>Prop names that have no mapping in the widget schema v1.</summary>
    static readonly HashSet<string> UnsupportedPropKeys =
        new(StringComparer.OrdinalIgnoreCase)
        {
            "variant", "color", "icon", "ripple", "elevation",
            "shape", "density", "tone", "corner_radius",
        };

    /// <summary>
    /// Translates a component spec JSON string into a <see cref="TranslationResult"/>.
    /// Never throws; parse failures are recorded in <see cref="TranslationResult.Errors"/>.
    /// </summary>
    public static TranslationResult Translate(string specJson)
    {
        var result = new TranslationResult();

        JsonNode? root;
        try { root = JsonNode.Parse(specJson); }
        catch (JsonException ex)
        {
            result.Errors.Add($"Invalid JSON: {ex.Message}");
            return result;
        }

        if (root is not JsonObject obj)
        {
            result.Errors.Add("Spec root must be a JSON object.");
            return result;
        }

        if (!obj.ContainsKey("spec_version"))
            result.Warnings.Add("spec_version field missing — assuming compatible format.");

        if (obj["components"] is not JsonArray components)
        {
            result.Errors.Add("components array is required.");
            return result;
        }

        for (int i = 0; i < components.Count; i++)
        {
            if (components[i] is not JsonObject comp)
            {
                result.Errors.Add($"components[{i}]: expected an object.");
                continue;
            }
            TranslateComponent(comp, i, result);
        }

        return result;
    }

    /// <summary>
    /// Serialises a <see cref="WidgetNodeDescriptor"/> to widget tree schema JSON
    /// (schema_version "1.0" is injected at the root).
    /// The output is accepted by <see cref="WidgetSchemaValidator.ValidateWidgetTree"/>.
    /// </summary>
    public static string DescriptorToSchemaJson(WidgetNodeDescriptor desc)
    {
        var sb = new StringBuilder();
        WriteNode(desc, sb, isRoot: true);
        return sb.ToString();
    }

    // ── internal ──────────────────────────────────────────────────────────────

    static void TranslateComponent(JsonObject comp, int index, TranslationResult result)
    {
        var name = "";
        try { name = comp["name"]?.GetValue<string>() ?? ""; } catch { }

        if (string.IsNullOrWhiteSpace(name))
        {
            result.Errors.Add($"components[{index}].name: required field missing or empty.");
            return;
        }

        if (!TypeMap.TryGetValue(name, out var widgetType))
        {
            result.Warnings.Add($"Component \"{name}\": no widget type mapping — skipped.");
            return;
        }

        var desc = new WidgetNodeDescriptor { Type = widgetType };

        // Size from width_dp / height_dp shorthand at component level
        float widthM = DefaultSize[0];
        float heightM = DefaultSize[1];
        if (TryGetFloat(comp["width_dp"], out var wdp)) widthM = wdp * DpToMeters;
        if (TryGetFloat(comp["height_dp"], out var hdp)) heightM = hdp * DpToMeters;

        // Props
        if (comp["props"] is JsonObject props)
            ApplyProps(props, desc, ref widthM, ref heightM, name, result);

        desc.Size = [widthM, heightM];

        // Events and states → warnings only
        if (comp["events"] is JsonArray events && events.Count > 0)
            result.Warnings.Add($"Component \"{name}\": events {JsonList(events)} have no schema v1 equivalent — ignored.");

        if (comp["states"] is JsonArray states && states.Count > 0)
            result.Warnings.Add($"Component \"{name}\": states {JsonList(states)} are expressed via theme tokens, not schema fields — ignored.");

        result.Descriptors.Add(desc);
    }

    static void ApplyProps(
        JsonObject props, WidgetNodeDescriptor desc,
        ref float widthM, ref float heightM,
        string componentName, TranslationResult result)
    {
        foreach (var kv in props)
        {
            var key = kv.Key;
            var val = kv.Value;

            if (UnsupportedPropKeys.Contains(key))
            {
                result.Warnings.Add($"Component \"{componentName}\": prop \"{key}\" has no widget schema equivalent — ignored.");
                continue;
            }

            if (key.Equals("label", StringComparison.OrdinalIgnoreCase) ||
                key.Equals("text", StringComparison.OrdinalIgnoreCase))
            {
                // May be a prop descriptor object or a plain string default
                desc.Text = ExtractStringDefault(val);
                continue;
            }

            if (key.Equals("disabled", StringComparison.OrdinalIgnoreCase))
            {
                desc.Enabled = !(ExtractBoolDefault(val) ?? false);
                continue;
            }

            if (key.Equals("checked", StringComparison.OrdinalIgnoreCase) ||
                key.Equals("value", StringComparison.OrdinalIgnoreCase))
            {
                if (TryExtractNumberDefault(val, out var v))
                    desc.Value = v;
                else if (ExtractBoolDefault(val) is bool b)
                    desc.Value = b ? 1f : 0f;
                continue;
            }

            // width / height with optional unit
            if (key.Equals("width", StringComparison.OrdinalIgnoreCase) ||
                key.Equals("width_dp", StringComparison.OrdinalIgnoreCase))
            {
                if (TryExtractNumberDefault(val, out var w))
                {
                    bool isDp = key.EndsWith("_dp", StringComparison.OrdinalIgnoreCase) || IsUnitDp(val);
                    widthM = isDp ? w * DpToMeters : w;
                }
                continue;
            }

            if (key.Equals("height", StringComparison.OrdinalIgnoreCase) ||
                key.Equals("height_dp", StringComparison.OrdinalIgnoreCase))
            {
                if (TryExtractNumberDefault(val, out var h))
                {
                    bool isDp = key.EndsWith("_dp", StringComparison.OrdinalIgnoreCase) || IsUnitDp(val);
                    heightM = isDp ? h * DpToMeters : h;
                }
                continue;
            }

            // min / max on sliders — noted but not stored in schema v1
            if (key.Equals("min", StringComparison.OrdinalIgnoreCase) ||
                key.Equals("max", StringComparison.OrdinalIgnoreCase))
            {
                result.Warnings.Add($"Component \"{componentName}\": prop \"{key}\" has no widget schema v1 field — ignored.");
                continue;
            }

            result.Warnings.Add($"Component \"{componentName}\": prop \"{key}\" is unknown — ignored.");
        }
    }

    // ── prop descriptor helpers ───────────────────────────────────────────────

    static string? ExtractStringDefault(JsonNode? node)
    {
        // Plain string value
        if (node is JsonValue sv) { try { return sv.GetValue<string>(); } catch { } }
        // Prop descriptor: { "type": "string", "default": "..." }
        if (node is JsonObject obj)
        {
            try { return obj["default"]?.GetValue<string>(); } catch { }
        }
        return null;
    }

    static bool? ExtractBoolDefault(JsonNode? node)
    {
        if (node is JsonValue bv) { try { return bv.GetValue<bool>(); } catch { } }
        if (node is JsonObject obj)
        {
            if (obj["default"] is JsonValue dv) { try { return dv.GetValue<bool>(); } catch { } }
        }
        return null;
    }

    static bool TryExtractNumberDefault(JsonNode? node, out float value)
    {
        value = 0f;
        if (TryGetFloat(node, out value)) return true;
        if (node is JsonObject obj && TryGetFloat(obj["default"], out value)) return true;
        return false;
    }

    static bool IsUnitDp(JsonNode? node)
    {
        if (node is not JsonObject obj) return false;
        try { return (obj["unit"]?.GetValue<string>() ?? "").Equals("dp", StringComparison.OrdinalIgnoreCase); }
        catch { return false; }
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

    static string JsonList(JsonArray arr)
    {
        var parts = new List<string>();
        foreach (var item in arr)
        {
            try { parts.Add(item?.GetValue<string>() ?? "?"); } catch { parts.Add("?"); }
        }
        return "[" + string.Join(", ", parts) + "]";
    }

    // ── serialiser ────────────────────────────────────────────────────────────

    static void WriteNode(WidgetNodeDescriptor desc, StringBuilder sb, bool isRoot)
    {
        sb.Append('{');
        if (isRoot)
            sb.Append("\"schema_version\":\"1.0\",");

        sb.Append($"\"type\":{JsonString(desc.Type)}");

        if (desc.Size != null)
            sb.Append($",\"size\":[{F(desc.Size[0])},{F(desc.Size[1])}]");

        if (!desc.Enabled)
            sb.Append(",\"enabled\":false");

        if (desc.Text != null)
            sb.Append($",\"text\":{JsonString(desc.Text)}");

        if (desc.Value.HasValue)
            sb.Append($",\"value\":{F(desc.Value.Value)}");

        if (desc.Theme != null)
            sb.Append($",\"theme\":{JsonString(desc.Theme)}");

        if (desc.Children.Count > 0)
        {
            sb.Append(",\"children\":[");
            for (int i = 0; i < desc.Children.Count; i++)
            {
                if (i > 0) sb.Append(',');
                WriteNode(desc.Children[i], sb, isRoot: false);
            }
            sb.Append(']');
        }

        sb.Append('}');
    }

    static string JsonString(string s) =>
        JsonSerializer.Serialize(s);

    static string F(float v) =>
        v.ToString("0.######", System.Globalization.CultureInfo.InvariantCulture);
}
