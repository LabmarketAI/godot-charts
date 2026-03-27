using System.IO;
using System.Linq;
using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestWidgetSpecTranslator
{
    static string Fixture(string name) =>
        File.ReadAllText(Path.Combine(TestContext.CurrentContext.TestDirectory, "Fixtures", name));

    // ── inputs family ─────────────────────────────────────────────────────────

    [Test]
    public void InputsFamily_ProducesThreeDescriptors()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        Assert.That(result.HasErrors, Is.False, string.Join("\n", result.Errors));
        Assert.That(result.Descriptors, Has.Count.EqualTo(3));
    }

    [Test]
    public void InputsFamily_Button_MapsToCorrectType()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        var button = result.Descriptors[0];
        Assert.That(button.Type, Is.EqualTo("button"));
    }

    [Test]
    public void InputsFamily_Button_SizeConvertedFromDp()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        var button = result.Descriptors[0];
        Assert.That(button.Size, Is.Not.Null);
        Assert.That(button.Size![0], Is.EqualTo(0.088f).Within(0.0001f)); // 88 dp
        Assert.That(button.Size![1], Is.EqualTo(0.040f).Within(0.0001f)); // 40 dp
    }

    [Test]
    public void InputsFamily_Switch_MapsToToggle()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        var toggle = result.Descriptors[1];
        Assert.That(toggle.Type, Is.EqualTo("toggle"));
        Assert.That(toggle.Size![0], Is.EqualTo(0.052f).Within(0.0001f)); // 52 dp
        Assert.That(toggle.Size![1], Is.EqualTo(0.032f).Within(0.0001f)); // 32 dp
    }

    [Test]
    public void InputsFamily_Slider_MapsCorrectly()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        var slider = result.Descriptors[2];
        Assert.That(slider.Type, Is.EqualTo("slider"));
        Assert.That(slider.Value, Is.EqualTo(0f).Within(0.0001f));
        Assert.That(slider.Size![0], Is.EqualTo(0.2f).Within(0.0001f)); // 200 dp
    }

    [Test]
    public void InputsFamily_Events_ProduceWarnings()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        Assert.That(result.Warnings, Has.Some.Contains("events"));
    }

    [Test]
    public void InputsFamily_States_ProduceWarnings()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        Assert.That(result.Warnings, Has.Some.Contains("states"));
    }

    // ── display family ────────────────────────────────────────────────────────

    [Test]
    public void DisplayFamily_ProducesTwoDescriptors()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_display.json"));
        Assert.That(result.HasErrors, Is.False, string.Join("\n", result.Errors));
        Assert.That(result.Descriptors, Has.Count.EqualTo(2));
    }

    [Test]
    public void DisplayFamily_Label_MapsCorrectly()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_display.json"));
        var label = result.Descriptors[0];
        Assert.That(label.Type, Is.EqualTo("label"));
        Assert.That(label.Size![0], Is.EqualTo(0.16f).Within(0.0001f)); // 160 dp
    }

    [Test]
    public void DisplayFamily_ListItem_MapsCorrectly()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_display.json"));
        var item = result.Descriptors[1];
        Assert.That(item.Type, Is.EqualTo("list_item"));
        Assert.That(item.Size![0], Is.EqualTo(0.28f).Within(0.0001f)); // 280 dp
        Assert.That(item.Size![1], Is.EqualTo(0.048f).Within(0.0001f)); // 48 dp
    }

    // ── unknown types + unsupported props ─────────────────────────────────────

    [Test]
    public void UnknownTypes_UnmappedComponent_IsSkippedWithWarning()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_unknown_types.json"));
        // DatePicker has no mapping
        Assert.That(result.Descriptors.Any(d => d.Type == "button" || d.Type == "slider"), Is.True);
        Assert.That(result.Warnings, Has.Some.Contains("DatePicker"));
    }

    [Test]
    public void UnknownTypes_UnsupportedProps_ProduceWarnings()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_unknown_types.json"));
        Assert.That(result.Warnings, Has.Some.Contains("variant"));
        Assert.That(result.Warnings, Has.Some.Contains("icon"));
    }

    [Test]
    public void UnknownTypes_MinMaxProps_ProduceWarnings()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_unknown_types.json"));
        Assert.That(result.Warnings, Has.Some.Contains("min").Or.Contains("max"));
    }

    [Test]
    public void UnknownTypes_KnownComponents_AreStillTranslated()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_unknown_types.json"));
        // Button and Slider should translate despite unsupported props
        Assert.That(result.Descriptors, Has.Count.EqualTo(2));
        Assert.That(result.Descriptors[0].Type, Is.EqualTo("button"));
        Assert.That(result.Descriptors[1].Type, Is.EqualTo("slider"));
    }

    // ── malformed input ───────────────────────────────────────────────────────

    [Test]
    public void MalformedJson_ReturnsError()
    {
        var result = WidgetSpecTranslator.Translate("{ not json");
        Assert.That(result.HasErrors, Is.True);
        Assert.That(result.Errors[0], Does.StartWith("Invalid JSON"));
    }

    [Test]
    public void MissingComponentsArray_ReturnsError()
    {
        var result = WidgetSpecTranslator.Translate("{\"spec_version\":\"1.0\"}");
        Assert.That(result.HasErrors, Is.True);
        Assert.That(result.Errors[0], Does.Contain("components"));
    }

    // ── end-to-end round-trip: translate → serialise → validate ──────────────

    [Test]
    public void InputsFamily_AllDescriptors_ProduceValidSchemaJson()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_inputs.json"));
        Assert.That(result.HasErrors, Is.False);

        foreach (var desc in result.Descriptors)
        {
            var json = WidgetSpecTranslator.DescriptorToSchemaJson(desc);
            var validation = WidgetSchemaValidator.ValidateWidgetTree(json);
            Assert.That(validation.IsValid, Is.True,
                $"Descriptor type={desc.Type} produced invalid schema:\n{json}\nErrors:\n{string.Join("\n", validation.Errors)}");
        }
    }

    [Test]
    public void DisplayFamily_AllDescriptors_ProduceValidSchemaJson()
    {
        var result = WidgetSpecTranslator.Translate(Fixture("component_spec_display.json"));
        Assert.That(result.HasErrors, Is.False);

        foreach (var desc in result.Descriptors)
        {
            var json = WidgetSpecTranslator.DescriptorToSchemaJson(desc);
            var validation = WidgetSchemaValidator.ValidateWidgetTree(json);
            Assert.That(validation.IsValid, Is.True,
                $"Descriptor type={desc.Type} produced invalid schema:\n{json}\nErrors:\n{string.Join("\n", validation.Errors)}");
        }
    }

    [Test]
    public void DescriptorToSchemaJson_DisabledProp_RoundTrips()
    {
        const string spec = """
            {
              "spec_version":"1.0",
              "components":[
                {"name":"Button","props":{"disabled":{"type":"boolean","default":true},"width_dp":88,"height_dp":40}}
              ]
            }
            """;
        var result = WidgetSpecTranslator.Translate(spec);
        Assert.That(result.Descriptors[0].Enabled, Is.False);

        var json = WidgetSpecTranslator.DescriptorToSchemaJson(result.Descriptors[0]);
        var validation = WidgetSchemaValidator.ValidateWidgetTree(json);
        Assert.That(validation.IsValid, Is.True, string.Join("\n", validation.Errors));

        var imported = WidgetSchemaImporter.ImportWidgetTree(json);
        Assert.That(imported!.Enabled, Is.False);
    }
}
