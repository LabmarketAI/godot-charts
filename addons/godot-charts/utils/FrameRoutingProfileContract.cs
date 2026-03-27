namespace GodotCharts;

public readonly record struct FrameRoutingProfile(
    string BusId,
    string TopicId,
    string TopicProfileId,
    string ChartTypeMappingMode,
    bool ManualChartTypeLock);

public static class FrameRoutingProfileContract
{
    public const string BusIdKey = "bus_id";
    public const string TopicIdKey = "topic_id";
    public const string TopicProfileIdKey = "topic_profile_id";
    public const string ChartTypeMappingModeKey = "chart_type_mapping_mode";
    public const string ManualChartTypeLockKey = "manual_chart_type_lock";

    public const string DefaultBusId = "demo_stream";
    public const string DefaultChartTypeMappingMode = "manual";
    public const bool DefaultManualChartTypeLock = true;

    public static FrameRoutingProfile CreateDefault(string chartType)
    {
        return new FrameRoutingProfile(
            DefaultBusId,
            BuildDefaultTopicId(chartType),
            "",
            DefaultChartTypeMappingMode,
            DefaultManualChartTypeLock);
    }

    public static string NormalizeBusId(string? busId)
    {
        return string.IsNullOrWhiteSpace(busId) ? DefaultBusId : busId.Trim();
    }

    public static string NormalizeTopicId(string? topicId, string chartType)
    {
        return string.IsNullOrWhiteSpace(topicId) ? BuildDefaultTopicId(chartType) : topicId.Trim();
    }

    public static string NormalizeTopicProfileId(string? topicProfileId)
    {
        return string.IsNullOrWhiteSpace(topicProfileId) ? "" : topicProfileId.Trim();
    }

    public static string NormalizeChartTypeMappingMode(string? mappingMode)
    {
        if (string.IsNullOrWhiteSpace(mappingMode))
            return DefaultChartTypeMappingMode;

        var normalized = mappingMode.Trim().ToLowerInvariant();
        return normalized switch
        {
            "suggested" => "suggested",
            _ => DefaultChartTypeMappingMode,
        };
    }

    public static string BuildDefaultTopicId(string chartType)
    {
        return $"demo/stream/{NormalizeTopicChartType(chartType)}";
    }

    private static string NormalizeTopicChartType(string chartType)
    {
        if (string.IsNullOrWhiteSpace(chartType))
            return "bar";

        var normalized = chartType.Trim().ToLowerInvariant();
        return normalized switch
        {
            "network" => "graph_network",
            "graph_network" => "graph_network",
            _ => normalized,
        };
    }
}