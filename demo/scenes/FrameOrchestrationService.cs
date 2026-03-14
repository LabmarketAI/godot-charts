using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using GodotCharts;

public partial class FrameOrchestrationService : Node
{
	[Signal]
	public delegate void RuntimeFramesChangedEventHandler();

	private const string RuntimeContainerName = "RuntimeFrames";
	private const float RuntimeRingRadius = 6.0f;
	private const float RuntimeRingHeight = 1.0f;

	private readonly System.Collections.Generic.Dictionary<string, ChartFrame3D> _framesById = new();
	private Node3D? _dataRoom;
	private Node3D? _runtimeContainer;
	private WorkspaceStateService? _workspaceService;

	public static readonly string[] SupportedChartTypes =
	{
		"bar", "line", "scatter", "surface", "histogram", "network", "circuit",
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

	public bool CreateFrame(string chartType, string sizePreset)
	{
		if (_runtimeContainer == null)
			return false;

		chartType = NormalizeChartType(chartType);
		sizePreset = NormalizeSizePreset(sizePreset);

		var id = $"runtime-{DateTime.UtcNow:yyyyMMdd-HHmmssfff}";
		var frame = new ChartFrame3D
		{
			Name = id,
			Size = SizeForPreset(sizePreset),
		};
		frame.Position = ComputeSpawnPosition(_framesById.Count);
		frame.LookAt(new Vector3(0f, RuntimeRingHeight + 0.8f, 0f), Vector3.Up);

		_runtimeContainer.AddChild(frame);
		_framesById[id] = frame;

		SetFrameChartType(id, chartType, persist: false);
		PersistWorkspaceFrames();
		EmitSignal(SignalName.RuntimeFramesChanged);
		return true;
	}

	public bool DeleteFrame(string frameId)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		_framesById.Remove(frameId);
		frame.QueueFree();
		PersistWorkspaceFrames();
		EmitSignal(SignalName.RuntimeFramesChanged);
		return true;
	}

	public bool SetFrameChartType(string frameId, string chartType, bool persist = true)
	{
		if (!_framesById.TryGetValue(frameId, out var frame))
			return false;

		chartType = NormalizeChartType(chartType);
		ReplaceFrameChart(frame, chartType);

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

			if (child is Node node && node.Name == "RuntimeChart")
				node.QueueFree();
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

	private static Dictionary BuildFrameProfile(string frameId, ChartFrame3D frame)
	{
		var chartType = "bar";
		foreach (var child in frame.GetChildren())
		{
			if (child is BarChart3D) chartType = "bar";
			else if (child is LineChart3D) chartType = "line";
			else if (child is ScatterChart3D) chartType = "scatter";
			else if (child is SurfaceChart3D) chartType = "surface";
			else if (child is HistogramChart3D) chartType = "histogram";
			else if (child is GraphNetworkChart3D) chartType = "network";
			else if (child is CircuitChart3D) chartType = "circuit";
		}

		return new Dictionary
		{
			{ "id", frameId },
			{ "chart_type", chartType },
			{ "size_preset", PresetForSize(frame.Size) },
			{ "frame_size", SerializeVector2(frame.Size) },
			{ "position", SerializeVector3(frame.Position) },
			{ "rotation_degrees", SerializeVector3(frame.RotationDegrees) },
		};
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
}