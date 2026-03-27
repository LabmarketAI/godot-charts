using System.IO;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestWidgetSchemaValidator
{
    static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(TestContext.CurrentContext.TestDirectory, "Fixtures", name));

    // ── widget tree ───────────────────────────────────────────────────────────

    [Test]
    public void ValidWidgetTree_PassesValidation()
    {
        var result = WidgetSchemaValidator.ValidateWidgetTree(Fixture("widget_tree_valid.json"));
        Assert.That(result.IsValid, Is.True, string.Join("\n", result.Errors));
    }

    [Test]
    public void InvalidWidgetTree_MissingType_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateWidgetTree(Fixture("widget_tree_invalid_missing_type.json"));
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.type"));
    }

    [Test]
    public void InvalidWidgetTree_BadSize_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateWidgetTree(Fixture("widget_tree_invalid_bad_size.json"));
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.size[0]"));
    }

    [Test]
    public void InvalidWidgetTree_UnknownType_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateWidgetTree(Fixture("widget_tree_invalid_unknown_type.json"));
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("data_table"));
    }

    [Test]
    public void InvalidWidgetTree_MalformedJson_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateWidgetTree("{ not valid json");
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors[0], Does.StartWith("Invalid JSON"));
    }

    [Test]
    public void ValidWidgetTree_ErrorPathIsAccurate_ForNestedChild()
    {
        const string json = """
            {
              "schema_version": "1.0",
              "type": "widget_panel",
              "children": [
                {
                  "type": "row",
                  "children": [
                    { "text": "no type here" }
                  ]
                }
              ]
            }
            """;
        var result = WidgetSchemaValidator.ValidateWidgetTree(json);
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.children[0].children[0].type"));
    }

    [Test]
    public void ValidWidgetTree_SizeWithThreeElements_ReportsError()
    {
        const string json = """
            {"schema_version":"1.0","type":"button","size":[0.1,0.1,0.1]}
            """;
        var result = WidgetSchemaValidator.ValidateWidgetTree(json);
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.size"));
    }

    // ── theme ─────────────────────────────────────────────────────────────────

    [Test]
    public void ValidTheme_PassesValidation()
    {
        var result = WidgetSchemaValidator.ValidateTheme(Fixture("theme_valid.json"));
        Assert.That(result.IsValid, Is.True, string.Join("\n", result.Errors));
    }

    [Test]
    public void InvalidTheme_UnknownColorToken_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateTheme(Fixture("theme_invalid_unknown_color.json"));
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("highlight"));
    }

    [Test]
    public void InvalidTheme_MissingId_ReportsError()
    {
        var result = WidgetSchemaValidator.ValidateTheme(Fixture("theme_invalid_missing_required.json"));
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.id"));
    }

    [Test]
    public void InvalidTheme_NegativeTextSize_ReportsError()
    {
        const string json = """
            {
              "schema_version":"1.0","id":"x",
              "colors":{"bg_normal":"#000000"},
              "sizes":{"text_size":-1,"border_width":0.004}
            }
            """;
        var result = WidgetSchemaValidator.ValidateTheme(json);
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.sizes.text_size"));
    }

    [Test]
    public void InvalidTheme_BadColorHex_ReportsError()
    {
        const string json = """
            {
              "schema_version":"1.0","id":"x",
              "colors":{"bg_normal":"not-a-color"},
              "sizes":{"text_size":18,"border_width":0.004}
            }
            """;
        var result = WidgetSchemaValidator.ValidateTheme(json);
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("$.colors.bg_normal"));
    }

    [Test]
    public void InvalidTheme_UnknownSizeToken_ReportsError()
    {
        const string json = """
            {
              "schema_version":"1.0","id":"x",
              "colors":{},
              "sizes":{"text_size":18,"border_width":0.004,"shadow_blur":2.0}
            }
            """;
        var result = WidgetSchemaValidator.ValidateTheme(json);
        Assert.That(result.IsValid, Is.False);
        Assert.That(result.Errors, Has.Some.Contains("shadow_blur"));
    }
}
