using System;
using System.IO;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestWidgetThemeEngine
{
    static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(TestContext.CurrentContext.TestDirectory, "Fixtures", name));

    // ── preset access ─────────────────────────────────────────────────────────

    [Test]
    public void GetPreset_Neutral_ReturnsNeutralDescriptor()
    {
        var preset = WidgetThemeEngine.GetPreset("neutral");
        Assert.That(preset.Id, Is.EqualTo("neutral"));
    }

    [Test]
    public void GetPreset_HighContrast_ReturnsHighContrastDescriptor()
    {
        var preset = WidgetThemeEngine.GetPreset("high_contrast");
        Assert.That(preset.Id, Is.EqualTo("high_contrast"));
    }

    [Test]
    public void GetPreset_UnknownName_ThrowsArgumentException()
    {
        Assert.Throws<ArgumentException>(() => WidgetThemeEngine.GetPreset("neon_purple"));
    }

    // ── preset completeness ───────────────────────────────────────────────────

    [TestCase("neutral")]
    [TestCase("high_contrast")]
    public void Preset_HasAllRequiredColorTokens(string presetName)
    {
        var preset = WidgetThemeEngine.GetPreset(presetName);
        foreach (var token in WidgetThemeEngine.RequiredColorTokens)
            Assert.That(preset.Colors, Contains.Key(token),
                $"Preset \"{presetName}\" is missing color token \"{token}\".");
    }

    [TestCase("neutral")]
    [TestCase("high_contrast")]
    public void Preset_HasAllRequiredSizeTokens(string presetName)
    {
        var preset = WidgetThemeEngine.GetPreset(presetName);
        foreach (var token in WidgetThemeEngine.RequiredSizeTokens)
            Assert.That(preset.Sizes, Contains.Key(token),
                $"Preset \"{presetName}\" is missing size token \"{token}\".");
    }

    [TestCase("neutral")]
    [TestCase("high_contrast")]
    public void Preset_AllColorTokensAreValidHexStrings(string presetName)
    {
        var preset = WidgetThemeEngine.GetPreset(presetName);
        foreach (var kv in preset.Colors)
        {
            var result = WidgetSchemaValidator.ValidateTheme(
                $"{{\"schema_version\":\"1.0\",\"id\":\"{presetName}\",\"colors\":{{" +
                $"\"{kv.Key}\":\"{kv.Value}\"" +
                $"}},\"sizes\":{{\"text_size\":18,\"border_width\":0.004}}}}");
            Assert.That(result.Errors, Has.None.Contains(kv.Key),
                $"Color token \"{kv.Key}\" = \"{kv.Value}\" failed validator.");
        }
    }

    // ── preset distinctness ───────────────────────────────────────────────────

    [Test]
    public void NeutralAndHighContrast_HaveDifferentBgNormal()
    {
        var neutral = WidgetThemeEngine.NeutralPreset;
        var highContrast = WidgetThemeEngine.HighContrastPreset;
        Assert.That(neutral.Colors["bg_normal"], Is.Not.EqualTo(highContrast.Colors["bg_normal"]));
    }

    [Test]
    public void HighContrast_HasLargerTextSize()
    {
        Assert.That(WidgetThemeEngine.HighContrastPreset.Sizes["text_size"],
            Is.GreaterThan(WidgetThemeEngine.NeutralPreset.Sizes["text_size"]));
    }

    [Test]
    public void HighContrast_HasWiderBorder()
    {
        Assert.That(WidgetThemeEngine.HighContrastPreset.Sizes["border_width"],
            Is.GreaterThan(WidgetThemeEngine.NeutralPreset.Sizes["border_width"]));
    }

    // ── token resolution + fallback ───────────────────────────────────────────

    [Test]
    public void ResolveColor_ReturnsThemeValue_WhenPresent()
    {
        var theme = WidgetThemeEngine.NeutralPreset;
        var result = WidgetThemeEngine.ResolveColor(theme, "accent");
        Assert.That(result, Is.EqualTo(theme.Colors["accent"]));
    }

    [Test]
    public void ResolveColor_FallsBackToFallbackDescriptor_WhenTokenMissing()
    {
        var sparse = new ThemeDescriptor { Id = "sparse", Colors = new() };
        var fallback = WidgetThemeEngine.NeutralPreset;
        var result = WidgetThemeEngine.ResolveColor(sparse, "bg_normal", fallback);
        Assert.That(result, Is.EqualTo(fallback.Colors["bg_normal"]));
    }

    [Test]
    public void ResolveColor_ReturnsLastResort_WhenNeitherSourceHasToken()
    {
        var sparse = new ThemeDescriptor { Id = "sparse", Colors = new() };
        var emptyFallback = new ThemeDescriptor { Id = "empty", Colors = new() };
        var result = WidgetThemeEngine.ResolveColor(sparse, "accent", emptyFallback);
        Assert.That(result, Is.EqualTo("#FFFFFF"));
    }

    [Test]
    public void ResolveColor_NoFallback_ReturnsLastResort_WhenTokenMissing()
    {
        var sparse = new ThemeDescriptor { Id = "sparse", Colors = new() };
        var result = WidgetThemeEngine.ResolveColor(sparse, "accent");
        Assert.That(result, Is.EqualTo("#FFFFFF"));
    }

    [Test]
    public void ResolveSize_ReturnsThemeValue_WhenPresent()
    {
        var theme = WidgetThemeEngine.NeutralPreset;
        var result = WidgetThemeEngine.ResolveSize(theme, "text_size");
        Assert.That(result, Is.EqualTo(theme.Sizes["text_size"]));
    }

    [Test]
    public void ResolveSize_FallsBackToFallbackDescriptor_WhenTokenMissing()
    {
        var sparse = new ThemeDescriptor { Id = "sparse", Sizes = new() };
        var fallback = WidgetThemeEngine.NeutralPreset;
        var result = WidgetThemeEngine.ResolveSize(sparse, "text_size", fallback);
        Assert.That(result, Is.EqualTo(fallback.Sizes["text_size"]));
    }

    [Test]
    public void ResolveSize_ReturnsZero_WhenNeitherSourceHasToken()
    {
        var sparse = new ThemeDescriptor { Id = "sparse", Sizes = new() };
        var result = WidgetThemeEngine.ResolveSize(sparse, "text_size");
        Assert.That(result, Is.EqualTo(0f));
    }

    // ── JSON preset files match engine presets ────────────────────────────────

    [Test]
    public void NeutralJsonFixture_MatchesEnginePreset()
    {
        // theme_valid.json is the canonical neutral preset fixture.
        var desc = WidgetSchemaImporter.ImportTheme(Fixture("theme_valid.json"));
        var preset = WidgetThemeEngine.NeutralPreset;
        Assert.That(desc!.Id, Is.EqualTo(preset.Id));
        Assert.That(desc.Colors["bg_normal"], Is.EqualTo(preset.Colors["bg_normal"]));
        Assert.That(desc.Sizes["text_size"], Is.EqualTo(preset.Sizes["text_size"]).Within(0.001f));
    }

    [Test]
    public void HighContrastJsonFixture_MatchesEnginePreset()
    {
        var desc = WidgetSchemaImporter.ImportTheme(Fixture("theme_high_contrast.json"));
        var preset = WidgetThemeEngine.HighContrastPreset;
        Assert.That(desc!.Id, Is.EqualTo(preset.Id));
        Assert.That(desc.Colors["bg_normal"], Is.EqualTo(preset.Colors["bg_normal"]));
        Assert.That(desc.Sizes["text_size"], Is.EqualTo(preset.Sizes["text_size"]).Within(0.001f));
    }

    [Test]
    public void HighContrastJsonFixture_PassesValidator()
    {
        var result = WidgetSchemaValidator.ValidateTheme(Fixture("theme_high_contrast.json"));
        Assert.That(result.IsValid, Is.True, string.Join("\n", result.Errors));
    }
}
