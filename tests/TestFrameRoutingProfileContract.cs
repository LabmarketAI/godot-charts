using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestFrameRoutingProfileContract
{
    [Test]
    public void CreateDefault_UsesExpectedDefaults()
    {
        var profile = FrameRoutingProfileContract.CreateDefault("line");

        Assert.That(profile.BusId, Is.EqualTo("demo_stream"));
        Assert.That(profile.TopicId, Is.EqualTo("demo/stream/line"));
        Assert.That(profile.TopicProfileId, Is.EqualTo(""));
        Assert.That(profile.ChartTypeMappingMode, Is.EqualTo("manual"));
        Assert.That(profile.ManualChartTypeLock, Is.True);
    }

    [Test]
    public void BuildDefaultTopicId_MapsNetworkAlias()
    {
        Assert.That(FrameRoutingProfileContract.BuildDefaultTopicId("network"), Is.EqualTo("demo/stream/graph_network"));
        Assert.That(FrameRoutingProfileContract.BuildDefaultTopicId("graph_network"), Is.EqualTo("demo/stream/graph_network"));
    }

    [Test]
    public void NormalizeBusId_UsesDefaultWhenMissing()
    {
        Assert.That(FrameRoutingProfileContract.NormalizeBusId(null), Is.EqualTo("demo_stream"));
        Assert.That(FrameRoutingProfileContract.NormalizeBusId("   "), Is.EqualTo("demo_stream"));
        Assert.That(FrameRoutingProfileContract.NormalizeBusId("custom_bus"), Is.EqualTo("custom_bus"));
    }

    [Test]
    public void NormalizeTopicId_UsesChartDefaultWhenMissing()
    {
        Assert.That(FrameRoutingProfileContract.NormalizeTopicId(null, "bar"), Is.EqualTo("demo/stream/bar"));
        Assert.That(FrameRoutingProfileContract.NormalizeTopicId("", "surface"), Is.EqualTo("demo/stream/surface"));
        Assert.That(FrameRoutingProfileContract.NormalizeTopicId(" custom/topic ", "bar"), Is.EqualTo("custom/topic"));
    }

    [Test]
    public void NormalizeChartTypeMappingMode_AllowsSuggestedOtherwiseManual()
    {
        Assert.That(FrameRoutingProfileContract.NormalizeChartTypeMappingMode(null), Is.EqualTo("manual"));
        Assert.That(FrameRoutingProfileContract.NormalizeChartTypeMappingMode(""), Is.EqualTo("manual"));
        Assert.That(FrameRoutingProfileContract.NormalizeChartTypeMappingMode("suggested"), Is.EqualTo("suggested"));
        Assert.That(FrameRoutingProfileContract.NormalizeChartTypeMappingMode("SUGGESTED"), Is.EqualTo("suggested"));
        Assert.That(FrameRoutingProfileContract.NormalizeChartTypeMappingMode("auto"), Is.EqualTo("manual"));
    }
}
