namespace GodotCharts;

public readonly record struct TopicChartMappingDecision(
    bool ShouldSwitch,
    string TargetChartType,
    string Reason);

public static class TopicChartMappingPolicy
{
    public static TopicChartMappingDecision Decide(
        string currentChartType,
        string suggestedChartType,
        string mappingMode,
        bool manualChartTypeLock)
    {
        var current = NormalizeFrameChartType(currentChartType);
        var target = NormalizeFrameChartType(suggestedChartType);
        var mode = FrameRoutingProfileContract.NormalizeChartTypeMappingMode(mappingMode);

        if (manualChartTypeLock)
            return new TopicChartMappingDecision(false, current, "manual_lock");

        if (mode != "suggested")
            return new TopicChartMappingDecision(false, current, "mapping_mode_manual");

        if (string.IsNullOrWhiteSpace(suggestedChartType))
            return new TopicChartMappingDecision(false, current, "missing_suggested_chart_type");

        if (current == target)
            return new TopicChartMappingDecision(false, current, "already_matching_chart_type");

        return new TopicChartMappingDecision(true, target, "switch_to_suggested_chart_type");
    }

    private static string NormalizeFrameChartType(string chartType)
    {
        if (string.IsNullOrWhiteSpace(chartType))
            return "bar";

        var normalized = chartType.Trim().ToLowerInvariant();
        normalized = normalized switch
        {
            "graph_network" => "network",
            _ => normalized,
        };

        return normalized switch
        {
            "line" => "line",
            "scatter" => "scatter",
            "surface" => "surface",
            "histogram" => "histogram",
            "network" => "network",
            "circuit" => "circuit",
            "desktop" => "desktop",
            _ => "bar",
        };
    }
}