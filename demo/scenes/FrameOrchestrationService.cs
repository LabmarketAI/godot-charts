using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using GodotCharts;

public partial class FrameOrchestrationService : Node
{
	public readonly record struct FrameDisplayIdentity(string DisplayName, int DisplayIndex);

	[Signal]
	public delegate void RuntimeFramesChangedEventHandler();

	private const string RuntimeContainerName = "RuntimeFrames";
	private const float RuntimeRingRadius = 6.0f;
	private const float RuntimeRingHeight = 1.0f;

	private readonly System.Collections.Generic.Dictionary<string, ChartFrame3D> _framesById = new();
	private readonly System.Collections.Generic.Dictionary<string, FrameRoutingProfile> _routingByFrameId = new();
	private readonly System.Collections.Generic.Dictionary<string, FrameDisplayIdentity> _identityByFrameId = new();
	private Node3D? _dataRoom;
	private Node3D? _runtimeContainer;
	private WorkspaceStateService? _workspaceService;
	private string _moveModeFrameId = "";
	private string _placementChartType = "";
	private string _placementSizePreset = "medium";

	public static readonly string[] SupportedChartTypes =
	{
		"bar", "line", "scatter", "surface", "histogram", "network", "circuit", "desktop",
	};

	public static readonly string[] SupportedSizePresets =
	{
		"compact", "medium", "large",
	};

	public void Initialize(Node3D dataRoom, WorkspaceStateService workspaceService)
	{
		_dataRoom = dataRoom;
		_workspaceService = workspaceService;

		_runtimeContainer = _dataRoom.GetNodeOrNull<Node3D>(RuntimeContainerName);
		if (_runtimeContainer == null)
		{
			_runtimeContainer = new Node3D { Name = RuntimeContainerName };
			_dataRoom.AddChild(_runtimeContainer);
		}

		_workspaceService.WorkspaceLoaded += OnWorkspaceLoaded;
		ApplyWorkspaceFrameState();
	}

	public Array<Dictionary> ListRuntimeFrameProfiles()
	{
		var profiles = new Array<Dictionary>();
		foreach (var id in _framesById.Keys)
		{
			profiles.Add(BuildFrameProfile(id, _framesById[id]));
		}
		return profiles;
	}

	public bool TryGetFrame(string frameId, out ChartFrame3D frame)
	{
		if (_framesById.TryGetValue(frameId, out var found))
		{
			frame = found;
			return true;
		}

		frame = null!;
		return false;
	}

	public string GetFrameChartType(string frameId)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return "bar";
		return DetectChartType(frame);
	}

	public bool TryGetFrameRoutingProfile(string frameId, out FrameRoutingProfile routing)
	{
		if (_routingByFrameId.TryGetValue(frameId, out routing))
			return true;

		routing = default;
		return false;
	}

	public bool TryGetFrameDisplayIdentity(string frameId, out FrameDisplayIdentity identity)
	{
		if (_identityByFrameId.TryGetValue(frameId, out identity))
			return true;

		identity = default;
		return false;
	}

	public bool SetFrameTopicRoute(string frameId, string topicId, string? busId = null, bool persist = true)
	{
		if (!_framesById.ContainsKey(frameId))
			return false;

		if (string.IsNullOrWhiteSpace(topicId))
		{
			GD.PushWarning($"Frame topic retarget rejected for '{frameId}': topic_id is required.");
			return false;
		}

		var chartType = GetFrameChartType(frameId);
		if (!_routingByFrameId.TryGetValue(frameId, out var current))
			current = FrameRoutingProfileContract.CreateDefault(chartType);

		var nextBusId = FrameRoutingProfileContract.NormalizeBusId(busId ?? current.BusId);
		var nextTopicId = topicId.Trim();
		if (string.IsNullOrWhiteSpace(nextTopicId))
		{
			GD.PushWarning($"Frame topic retarget rejected for '{frameId}': topic_id is empty after trim.");
			return false;
		}

		_routingByFrameId[frameId] = current with
		{
			BusId = nextBusId,
			TopicId = nextTopicId,
		};

		if (persist)
		{
			PersistWorkspaceFrames();
			EmitSignal(SignalName.RuntimeFramesChanged);
		}

		return true;
	}

	public bool SetFrameTopicMappingPolicy(string frameId, string mappingMode, bool manualChartTypeLock, bool persist = true)
	{
		if (!_framesById.ContainsKey(frameId))
			return false;

		var chartType = GetFrameChartType(frameId);
		if (!_routingByFrameId.TryGetValue(frameId, out var current))
			current = FrameRoutingProfileContract.CreateDefault(chartType);

		_routingByFrameId[frameId] = current with
		{
			ChartTypeMappingMode = FrameRoutingProfileContract.NormalizeChartTypeMappingMode(mappingMode),
			ManualChartTypeLock = manualChartTypeLock,
		};

		if (persist)
		{
			PersistWorkspaceFrames();
			EmitSignal(SignalName.RuntimeFramesChanged);
		}

		return true;
	}

	public string GetMoveModeFrameId()
	{
		return _moveModeFrameId;
	}

	public bool SetMoveModeFrame(string frameId)
	{
		if (string.IsNullOrWhiteSpace(frameId))
		{
			_moveModeFrameId = "";
			return true;
		}

		if (!_framesById.ContainsKey(frameId))
			return false;

		_moveModeFrameId = frameId;
		return true;
	}

	public bool BeginChartPlacement(string chartType, string sizePreset = "medium")
	{
		_placementChartType = NormalizeChartType(chartType);
		_placementSizePreset = NormalizeSizePreset(sizePreset);
		return true;
	}

	public void CancelChartPlacement()
	{
		_placementChartType = "";
		_placementSizePreset = "medium";
	}

	public string GetPlacementChartType()
	{
		return _placementChartType;
	}

	public string GetPlacementSizePreset()
	{
		return _placementSizePreset;
	}

	public bool IsChartPlacementActive()
	{
		return !string.IsNullOrWhiteSpace(_placementChartType);
	}

	public bool SetFrameTransform(string frameId, Vector3 position, Vector3 rotationDegrees, bool persist = true)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		frame.Position = position;
		frame.RotationDegrees = rotationDegrees;

		if (persist)
		{
			PersistWorkspaceFrames();
			EmitSignal(SignalName.RuntimeFramesChanged);
		}

		return true;
	}

	public bool TranslateFrame(string frameId, Vector3 delta, bool persist = true)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		return SetFrameTransform(frameId, frame.Position + delta, frame.RotationDegrees, persist);
	}

	public bool RotateFrameDegrees(string frameId, Vector3 deltaDegrees, bool persist = true)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		return SetFrameTransform(frameId, frame.Position, frame.RotationDegrees + deltaDegrees, persist);
	}

	public bool CreateFrame(string chartType, string sizePreset)
	{
		return !string.IsNullOrWhiteSpace(CreateFrameAndReturnId(chartType, sizePreset));
	}

	public string CreateFrameAndReturnId(string chartType, string sizePreset)
	{
		if (_runtimeContainer == null)
			return "";

		chartType = NormalizeChartType(chartType);
		sizePreset = NormalizeSizePreset(sizePreset);

		var id = $"runtime-{DateTime.UtcNow:yyyyMMdd-HHmmssfff}";
		var frame = new ChartFrame3D
		{
			Name = id,
			Size = SizeForPreset(sizePreset),
		};
		frame.Position = ComputeSpawnPosition(_framesById.Count);

		_runtimeContainer.AddChild(frame);
		frame.LookAt(new Vector3(0f, RuntimeRingHeight + 0.8f, 0f), Vector3.Up);
		_framesById[id] = frame;
		_identityByFrameId[id] = BuildDefaultIdentity(chartType);
		_routingByFrameId[id] = FrameRoutingProfileContract.CreateDefault(chartType);

		SetFrameChartType(id, chartType, persist: false);
		PersistWorkspaceFrames();
		EmitSignal(SignalName.RuntimeFramesChanged);
		return id;
	}

	public static Vector2 GetFrameSizeForPreset(string sizePreset)
	{
		return SizeForPreset(sizePreset);
	}

	public bool DeleteFrame(string frameId)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		_framesById.Remove(frameId);
		_routingByFrameId.Remove(frameId);
		_identityByFrameId.Remove(frameId);
		if (_moveModeFrameId == frameId)
			_moveModeFrameId = "";
		frame.QueueFree();
		PersistWorkspaceFrames();
		EmitSignal(SignalName.RuntimeFramesChanged);
		return true;
	}

	public bool SetFrameChartType(string frameId, string chartType, bool persist = true)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		var previousChartType = DetectChartType(frame);
		chartType = NormalizeChartType(chartType);
		ReplaceFrameChart(frame, chartType);
		UpdateRoutingTopicDefault(frameId, previousChartType, chartType);

		if (persist)
		{
			PersistWorkspaceFrames();
			EmitSignal(SignalName.RuntimeFramesChanged);
		}
		return true;
	}

	public bool SetFrameSizePreset(string frameId, string sizePreset)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		sizePreset = NormalizeSizePreset(sizePreset);
		frame.Size = SizeForPreset(sizePreset);
		PersistWorkspaceFrames();
		EmitSignal(SignalName.RuntimeFramesChanged);
		return true;
	}

	private void OnWorkspaceLoaded(string workspaceName)
	{
		ApplyWorkspaceFrameState();
	}

	private void ApplyWorkspaceFrameState()
	{
		if (_workspaceService == null || _runtimeContainer == null)
			return;

		foreach (var frame in _framesById.Values)
			frame.QueueFree();
		_framesById.Clear();
		_routingByFrameId.Clear();
		_identityByFrameId.Clear();

		if (!_workspaceService.ActiveWorkspaceProfile.TryGetValue("frames", out var framesVariant)
			|| framesVariant.VariantType != Variant.Type.Array)
		{
			EmitSignal(SignalName.RuntimeFramesChanged);
			return;
		}

		var profiles = framesVariant.AsGodotArray<Dictionary>();
		foreach (var profile in profiles)
			CreateFrameFromProfile(profile);

		EmitSignal(SignalName.RuntimeFramesChanged);
	}

	private void CreateFrameFromProfile(Dictionary profile)
	{
		if (_runtimeContainer == null)
			return;

		var frameId = profile.TryGetValue("id", out var idValue) ? idValue.AsString() : "";
		if (string.IsNullOrWhiteSpace(frameId))
			frameId = $"runtime-{DateTime.UtcNow:yyyyMMdd-HHmmssfff}";

		var chartType = profile.TryGetValue("chart_type", out var chartTypeValue)
			? NormalizeChartType(chartTypeValue.AsString())
			: "bar";

		var sizePreset = profile.TryGetValue("size_preset", out var sizePresetValue)
			? NormalizeSizePreset(sizePresetValue.AsString())
			: "medium";

		var frame = new ChartFrame3D
		{
			Name = frameId,
			Size = profile.TryGetValue("frame_size", out var frameSizeVariant)
				? ParseVector2(frameSizeVariant, SizeForPreset(sizePreset))
				: SizeForPreset(sizePreset),
			Position = profile.TryGetValue("position", out var positionVariant)
				? ParseVector3(positionVariant, ComputeSpawnPosition(_framesById.Count))
				: ComputeSpawnPosition(_framesById.Count),
			RotationDegrees = profile.TryGetValue("rotation_degrees", out var rotationVariant)
				? ParseVector3(rotationVariant, Vector3.Zero)
				: Vector3.Zero,
		};

		_runtimeContainer.AddChild(frame);
		_framesById[frameId] = frame;
		_identityByFrameId[frameId] = ParseFrameIdentity(profile, chartType);
		_routingByFrameId[frameId] = ParseRoutingProfile(profile, chartType);
		ReplaceFrameChart(frame, chartType);
	}

	private void PersistWorkspaceFrames()
	{
		if (_workspaceService == null)
			return;

		_workspaceService.ActiveWorkspaceProfile["frames"] = ListRuntimeFrameProfiles();
		_workspaceService.SaveActiveWorkspace();
	}

	private static string NormalizeChartType(string chartType)
	{
		if (string.IsNullOrWhiteSpace(chartType))
			return "bar";
		var lowered = chartType.Trim().ToLowerInvariant();
		foreach (var candidate in SupportedChartTypes)
		{
			if (candidate == lowered)
				return candidate;
		}
		return "bar";
	}

	private static string NormalizeSizePreset(string sizePreset)
	{
		if (string.IsNullOrWhiteSpace(sizePreset))
			return "medium";
		var lowered = sizePreset.Trim().ToLowerInvariant();
		foreach (var candidate in SupportedSizePresets)
		{
			if (candidate == lowered)
				return candidate;
		}
		return "medium";
	}

	private static Vector2 SizeForPreset(string sizePreset)
	{
		return NormalizeSizePreset(sizePreset) switch
		{
			"compact" => new Vector2(3.0f, 2.2f),
			"large" => new Vector2(6.0f, 4.2f),
			_ => new Vector2(4.0f, 3.0f),
		};
	}

	private static Vector3 ComputeSpawnPosition(int ordinal)
	{
		var angle = Mathf.DegToRad((ordinal % 10) * 36f);
		return new Vector3(
			Mathf.Cos(angle) * RuntimeRingRadius,
			RuntimeRingHeight,
			Mathf.Sin(angle) * RuntimeRingRadius);
	}

	private static void ReplaceFrameChart(ChartFrame3D frame, string chartType)
	{
		foreach (var child in frame.GetChildren())
		{
			if (child is Chart3D chart3D)
			{
				chart3D.QueueFree();
				continue;
			}

			if (child is Node node && (node.Name == "RuntimeChart" || node.Name == "RuntimeDesktopView"))
				node.QueueFree();
		}

		if (chartType == "desktop")
		{
			var desktopView = new RuntimeDesktopFrameView
			{
				Name = "RuntimeDesktopView",
			};
			desktopView.BindFrame(frame);
			frame.AddChild(desktopView);
			return;
		}

		Node3D chart = chartType switch
		{
			"line" => new LineChart3D(),
			"scatter" => new ScatterChart3D(),
			"surface" => new SurfaceChart3D(),
			"histogram" => new HistogramChart3D(),
			"network" => new GraphNetworkChart3D(),
			"circuit" => new CircuitChart3D { CircuitFilePath = "res://data/circuit_bell_qiskit.json" },
			_ => new BarChart3D(),
		};

		chart.Name = "RuntimeChart";
		frame.AddChild(chart);
	}

	private Dictionary BuildFrameProfile(string frameId, ChartFrame3D frame)
	{
		var chartType = DetectChartType(frame);
		if (!_identityByFrameId.TryGetValue(frameId, out var identity))
			identity = BuildDefaultIdentity(chartType);
		if (!_routingByFrameId.TryGetValue(frameId, out var routing))
			routing = FrameRoutingProfileContract.CreateDefault(chartType);

		return new Dictionary
		{
			{ "id", frameId },
			{ "display_name", identity.DisplayName },
			{ "display_index", identity.DisplayIndex },
			{ "chart_type", chartType },
			{ "size_preset", PresetForSize(frame.Size) },
			{ "frame_size", SerializeVector2(frame.Size) },
			{ "position", SerializeVector3(frame.Position) },
			{ "rotation_degrees", SerializeVector3(frame.RotationDegrees) },
			{ FrameRoutingProfileContract.BusIdKey, routing.BusId },
			{ FrameRoutingProfileContract.TopicIdKey, routing.TopicId },
			{ FrameRoutingProfileContract.TopicProfileIdKey, routing.TopicProfileId },
			{ FrameRoutingProfileContract.ChartTypeMappingModeKey, routing.ChartTypeMappingMode },
			{ FrameRoutingProfileContract.ManualChartTypeLockKey, routing.ManualChartTypeLock },
		};
	}

	private static string DetectChartType(ChartFrame3D frame)
	{
		var chartType = "bar";
		foreach (var child in frame.GetChildren())
		{
			if (child is HistogramChart3D) chartType = "histogram";
			else if (child is LineChart3D) chartType = "line";
			else if (child is ScatterChart3D) chartType = "scatter";
			else if (child is SurfaceChart3D) chartType = "surface";
			else if (child is GraphNetworkChart3D) chartType = "network";
			else if (child is CircuitChart3D) chartType = "circuit";
			else if (child is RuntimeDesktopFrameView) chartType = "desktop";
			else if (child is BarChart3D) chartType = "bar";
		}
		return chartType;
	}

	private static string PresetForSize(Vector2 size)
	{
		if (size.X <= 3.2f)
			return "compact";
		if (size.X >= 5.5f)
			return "large";
		return "medium";
	}

	private static Array<double> SerializeVector2(Vector2 value)
	{
		return new Array<double> { value.X, value.Y };
	}

	private static Array<double> SerializeVector3(Vector3 value)
	{
		return new Array<double> { value.X, value.Y, value.Z };
	}

	private static Vector2 ParseVector2(Variant variant, Vector2 fallback)
	{
		if (variant.VariantType != Variant.Type.Array)
			return fallback;
		var arr = variant.AsGodotArray();
		if (arr.Count < 2)
			return fallback;
		return new Vector2((float)arr[0].AsDouble(), (float)arr[1].AsDouble());
	}

	private static Vector3 ParseVector3(Variant variant, Vector3 fallback)
	{
		if (variant.VariantType != Variant.Type.Array)
			return fallback;
		var arr = variant.AsGodotArray();
		if (arr.Count < 3)
			return fallback;
		return new Vector3((float)arr[0].AsDouble(), (float)arr[1].AsDouble(), (float)arr[2].AsDouble());
	}

	private static FrameRoutingProfile ParseRoutingProfile(Dictionary profile, string chartType)
	{
		var busId = profile.TryGetValue(FrameRoutingProfileContract.BusIdKey, out var busIdVariant)
			? busIdVariant.AsString()
			: null;

		var topicId = profile.TryGetValue(FrameRoutingProfileContract.TopicIdKey, out var topicIdVariant)
			? topicIdVariant.AsString()
			: null;

		var topicProfileId = profile.TryGetValue(FrameRoutingProfileContract.TopicProfileIdKey, out var topicProfileIdVariant)
			? topicProfileIdVariant.AsString()
			: null;

		var chartTypeMappingMode = profile.TryGetValue(FrameRoutingProfileContract.ChartTypeMappingModeKey, out var mappingModeVariant)
			? mappingModeVariant.AsString()
			: null;

		var manualChartTypeLock = FrameRoutingProfileContract.DefaultManualChartTypeLock;
		if (profile.TryGetValue(FrameRoutingProfileContract.ManualChartTypeLockKey, out var manualLockVariant))
		{
			if (manualLockVariant.VariantType == Variant.Type.Bool)
				manualChartTypeLock = manualLockVariant.AsBool();
			else if (manualLockVariant.VariantType == Variant.Type.Int)
				manualChartTypeLock = manualLockVariant.AsInt32() != 0;
			else if (manualLockVariant.VariantType == Variant.Type.String && bool.TryParse(manualLockVariant.AsString(), out var parsedBool))
				manualChartTypeLock = parsedBool;
		}

		return new FrameRoutingProfile(
			FrameRoutingProfileContract.NormalizeBusId(busId),
			FrameRoutingProfileContract.NormalizeTopicId(topicId, chartType),
			FrameRoutingProfileContract.NormalizeTopicProfileId(topicProfileId),
			FrameRoutingProfileContract.NormalizeChartTypeMappingMode(chartTypeMappingMode),
			manualChartTypeLock);
	}

	private FrameDisplayIdentity ParseFrameIdentity(Dictionary profile, string chartType)
	{
		var fallback = BuildDefaultIdentity(chartType);

		var displayName = profile.TryGetValue("display_name", out var nameVariant)
			? nameVariant.AsString()
			: fallback.DisplayName;

		var displayIndex = fallback.DisplayIndex;
		if (profile.TryGetValue("display_index", out var indexVariant))
		{
			if (indexVariant.VariantType == Variant.Type.Int)
				displayIndex = Math.Max(1, indexVariant.AsInt32());
			else if (indexVariant.VariantType == Variant.Type.String && int.TryParse(indexVariant.AsString(), out var parsedIndex))
				displayIndex = Math.Max(1, parsedIndex);
		}

		if (string.IsNullOrWhiteSpace(displayName))
			displayName = $"Frame {displayIndex:00}";

		return new FrameDisplayIdentity(displayName.Trim(), displayIndex);
	}

	private FrameDisplayIdentity BuildDefaultIdentity(string chartType)
	{
		var nextIndex = 1;
		foreach (var identity in _identityByFrameId.Values)
			nextIndex = Math.Max(nextIndex, identity.DisplayIndex + 1);

		var normalized = NormalizeChartType(chartType);
		var prefix = normalized switch
		{
			"network" => "Graph",
			"desktop" => "Desktop",
			"circuit" => "Circuit",
			_ => char.ToUpperInvariant(normalized[0]) + normalized[1..],
		};

		return new FrameDisplayIdentity($"{prefix} {nextIndex:00}", nextIndex);
	}

	private void UpdateRoutingTopicDefault(string frameId, string previousChartType, string newChartType)
	{
		if (!_routingByFrameId.TryGetValue(frameId, out var routing))
		{
			_routingByFrameId[frameId] = FrameRoutingProfileContract.CreateDefault(newChartType);
			return;
		}

		var previousDefaultTopic = FrameRoutingProfileContract.BuildDefaultTopicId(previousChartType);
		if (string.IsNullOrWhiteSpace(routing.TopicId) || routing.TopicId == previousDefaultTopic)
		{
			routing = routing with { TopicId = FrameRoutingProfileContract.BuildDefaultTopicId(newChartType) };
			_routingByFrameId[frameId] = routing;
		}
	}
}