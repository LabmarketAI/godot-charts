using System;
using System.Collections.Generic;

namespace GodotCharts;

/// <summary>
/// Pure-C# theme preset definitions and token resolution with fallback.
/// The Godot runtime side (WidgetThemeManager3D autoload) builds on these descriptors.
/// </summary>
public static class WidgetThemeEngine
{
    /// <summary>All color token keys required by MVP controls.</summary>
    public static readonly IReadOnlyList<string> RequiredColorTokens = new[]
    {
        "bg_normal", "bg_hover", "bg_pressed", "bg_disabled", "bg_checked",
        "border_normal", "border_focused",
        "text_normal", "text_disabled",
        "accent", "slider_track", "slider_thumb"
    };

    /// <summary>All size token keys required by MVP controls.</summary>
    public static readonly IReadOnlyList<string> RequiredSizeTokens = new[]
    {
        "text_size", "border_width"
    };

    public static ThemeDescriptor NeutralPreset { get; } = BuildNeutral();
    public static ThemeDescriptor HighContrastPreset { get; } = BuildHighContrast();

    /// <summary>
    /// Returns the named built-in preset descriptor.
    /// Throws <see cref="ArgumentException"/> for unknown names.
    /// </summary>
    public static ThemeDescriptor GetPreset(string name) => name switch
    {
        "neutral"       => NeutralPreset,
        "high_contrast" => HighContrastPreset,
        _               => throw new ArgumentException($"Unknown theme preset: \"{name}\".", nameof(name))
    };

    /// <summary>
    /// Resolve a color token.  Falls back to <paramref name="fallback"/> then to "#FFFFFF"
    /// if neither source defines the token.
    /// </summary>
    public static string ResolveColor(ThemeDescriptor theme, string token,
        ThemeDescriptor? fallback = null)
    {
        if (theme.Colors.TryGetValue(token, out var val)) return val;
        if (fallback?.Colors.TryGetValue(token, out val) == true) return val!;
        return "#FFFFFF";
    }

    /// <summary>
    /// Resolve a size token.  Falls back to <paramref name="fallback"/> then to 0
    /// if neither source defines the token.
    /// </summary>
    public static float ResolveSize(ThemeDescriptor theme, string token,
        ThemeDescriptor? fallback = null)
    {
        if (theme.Sizes.TryGetValue(token, out var val)) return val;
        if (fallback?.Sizes.TryGetValue(token, out val) == true) return val;
        return 0f;
    }

    // ── preset builders ───────────────────────────────────────────────────────

    static ThemeDescriptor BuildNeutral() => new()
    {
        Id = "neutral",
        Colors = new Dictionary<string, string>
        {
            ["bg_normal"]      = "#2E2E33",
            ["bg_hover"]       = "#474752",
            ["bg_pressed"]     = "#1F73D1",
            ["bg_disabled"]    = "#232325",
            ["bg_checked"]     = "#1F73D1",
            ["border_normal"]  = "#595966",
            ["border_focused"] = "#4DA6FF",
            ["text_normal"]    = "#F2F2F2",
            ["text_disabled"]  = "#737373",
            ["accent"]         = "#1F73D1",
            ["slider_track"]   = "#404047",
            ["slider_thumb"]   = "#1F73D1",
        },
        Sizes = new Dictionary<string, float>
        {
            ["text_size"]    = 18f,
            ["border_width"] = 0.004f,
        },
    };

    static ThemeDescriptor BuildHighContrast() => new()
    {
        Id = "high_contrast",
        Colors = new Dictionary<string, string>
        {
            ["bg_normal"]      = "#000000",
            ["bg_hover"]       = "#333333",
            ["bg_pressed"]     = "#FFFF00",
            ["bg_disabled"]    = "#1A1A1A",
            ["bg_checked"]     = "#FFFF00",
            ["border_normal"]  = "#FFFFFF",
            ["border_focused"] = "#FFFF00",
            ["text_normal"]    = "#FFFFFF",
            ["text_disabled"]  = "#808080",
            ["accent"]         = "#FFFF00",
            ["slider_track"]   = "#333333",
            ["slider_thumb"]   = "#FFFF00",
        },
        Sizes = new Dictionary<string, float>
        {
            ["text_size"]    = 20f,
            ["border_width"] = 0.006f,
        },
    };
}
