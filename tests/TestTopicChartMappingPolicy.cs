using NUnit.Framework;
using GodotCharts;

namespace GodotChartsTests;

[TestFixture]
public class TestTopicChartMappingPolicy
{
    [Test]
    public void Decide_RejectsWhenManualLockEnabled()
    {
        var decision = TopicChartMappingPolicy.Decide("bar", "line", "suggested", manualChartTypeLock: true);

        Assert.That(decision.ShouldSwitch, Is.False);
        Assert.That(decision.TargetChartType, Is.EqualTo("bar"));
        Assert.That(decision.Reason, Is.EqualTo("manual_lock"));
    }

    [Test]
    public void Decide_RejectsWhenModeIsManual()
    {
        var decision = TopicChartMappingPolicy.Decide("bar", "line", "manual", manualChartTypeLock: false);

        Assert.That(decision.ShouldSwitch, Is.False);
        Assert.That(decision.Reason, Is.EqualTo("mapping_mode_manual"));
    }

    [Test]
    public void Decide_AllowsSuggestedSwitchWhenUnlocked()
    {
        var decision = TopicChartMappingPolicy.Decide("bar", "line", "suggested", manualChartTypeLock: false);

        Assert.That(decision.ShouldSwitch, Is.True);
        Assert.That(decision.TargetChartType, Is.EqualTo("line"));
        Assert.That(decision.Reason, Is.EqualTo("switch_to_suggested_chart_type"));
    }

    [Test]
    public void Decide_NormalizesGraphNetworkAliasToNetwork()
    {
        var decision = TopicChartMappingPolicy.Decide("bar", "graph_network", "suggested", manualChartTypeLock: false);

        Assert.That(decision.ShouldSwitch, Is.True);
        Assert.That(decision.TargetChartType, Is.EqualTo("network"));
    }

    [Test]
    public void Decide_RejectsWhenAlreadyMatching()
    {
        var decision = TopicChartMappingPolicy.Decide("network", "graph_network", "suggested", manualChartTypeLock: false);

        Assert.That(decision.ShouldSwitch, Is.False);
        Assert.That(decision.Reason, Is.EqualTo("already_matching_chart_type"));
    }
}
