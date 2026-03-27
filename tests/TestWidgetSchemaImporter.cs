using System.IO;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestWidgetSchemaImporter
{
    static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(TestContext.CurrentContext.TestDirectory, "Fixtures", name));

    // ── widget tree ───────────────────────────────────────────────────────────

    [Test]
    public void ImportValidWidgetTree_ReturnsDescriptor()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree(Fixture("widget_tree_valid.json"));
        Assert.That(desc, Is.Not.Null);
        Assert.That(desc!.Type, Is.EqualTo("widget_panel"));
    }

    [Test]
    public void ImportedTree_PreservesSize()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree(Fixture("widget_tree_valid.json"));
        Assert.That(desc!.Size, Is.Not.Null);
        Assert.That(desc.Size![0], Is.EqualTo(0.8f).Within(0.0001f));
        Assert.That(desc.Size![1], Is.EqualTo(0.6f).Within(0.0001f));
    }

    [Test]
    public void ImportedTree_PreservesNestedChildren()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree(Fixture("widget_tree_valid.json"));
        Assert.That(desc!.Children, Has.Count.EqualTo(3));

        var row = desc.Children[0];
        Assert.That(row.Type, Is.EqualTo("row"));
        Assert.That(row.Children, Has.Count.EqualTo(3));

        var label = row.Children[0];
        Assert.That(label.Type, Is.EqualTo("label"));
        Assert.That(label.Text, Is.EqualTo("Settings"));
    }

    [Test]
    public void ImportedTree_PreservesEnabledFlag()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree(Fixture("widget_tree_valid.json"));
        var button = desc!.Children[0].Children[1];
        Assert.That(button.Type, Is.EqualTo("button"));
        Assert.That(button.Enabled, Is.True);
    }

    [Test]
    public void ImportedTree_PreservesSliderValue()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree(Fixture("widget_tree_valid.json"));
        var slider = desc!.Children[1];
        Assert.That(slider.Type, Is.EqualTo("slider"));
        Assert.That(slider.Value, Is.EqualTo(0.5f).Within(0.0001f));
    }

    [Test]
    public void ImportWidgetTree_MalformedJson_ReturnsNull()
    {
        var desc = WidgetSchemaImporter.ImportWidgetTree("{ bad json");
        Assert.That(desc, Is.Null);
    }

    // ── theme ─────────────────────────────────────────────────────────────────

    [Test]
    public void ImportValidTheme_ReturnsDescriptor()
    {
        var desc = WidgetSchemaImporter.ImportTheme(Fixture("theme_valid.json"));
        Assert.That(desc, Is.Not.Null);
        Assert.That(desc!.Id, Is.EqualTo("neutral"));
    }

    [Test]
    public void ImportTheme_PopulatesColorMap()
    {
        var desc = WidgetSchemaImporter.ImportTheme(Fixture("theme_valid.json"));
        Assert.That(desc!.Colors, Contains.Key("bg_normal"));
        Assert.That(desc.Colors["bg_normal"], Is.EqualTo("#2E2E33"));
        Assert.That(desc.Colors, Has.Count.EqualTo(12));
    }

    [Test]
    public void ImportTheme_PopulatesSizes()
    {
        var desc = WidgetSchemaImporter.ImportTheme(Fixture("theme_valid.json"));
        Assert.That(desc!.Sizes, Contains.Key("text_size"));
        Assert.That(desc.Sizes["text_size"], Is.EqualTo(18f).Within(0.0001f));
        Assert.That(desc.Sizes["border_width"], Is.EqualTo(0.004f).Within(0.00001f));
    }

    [Test]
    public void ImportTheme_MalformedJson_ReturnsNull()
    {
        var desc = WidgetSchemaImporter.ImportTheme("not json at all");
        Assert.That(desc, Is.Null);
    }
}
