using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;
using GDArray = Godot.Collections.Array;
using GDDict = Godot.Collections.Dictionary;

public partial class DemoDataGenerator : Node
{
	private const string SchemaVersion = "1.0";
	private const double DefaultCadenceSeconds = 30.0;

	[Export(PropertyHint.Range, "1,300,1")]
	public double CadenceSeconds { get; set; } = DefaultCadenceSeconds;

	[Export]
	public bool DeterministicSeedEnabled { get; set; } = true;

	[Export]
	public int DeterministicSeed { get; set; } = 12345;

	private MessageBusService? _messageBus;
	private Timer? _publishTimer;
	private Random _rng = new(12345);
	private double _phase;
	private ulong _tick;

	public void Initialize(MessageBusService messageBus)
	{
		if (_messageBus == messageBus)
			return;

		if (_messageBus != null)
			_messageBus.RunningStateChanged -= OnBusRunningStateChanged;

		_messageBus = messageBus;
		_messageBus.RunningStateChanged += OnBusRunningStateChanged;

		ResetGenerator();
		EnsureTimer();

		if (_messageBus.IsRunning)
			Resume();
		else
			Pause();
	}

	public void ResetGenerator()
	{
		_rng = DeterministicSeedEnabled ? new Random(DeterministicSeed) : new Random();
		_phase = 0.0;
		_tick = 0;
	}

	public void Pause()
	{
		_publishTimer?.Stop();
	}

	public void Resume()
	{
		if (_publishTimer == null)
			return;

		_publishTimer.WaitTime = Math.Max(1.0, CadenceSeconds);
		PublishAllTopics();
		_publishTimer.Start();
	}

	private void EnsureTimer()
	{
		if (_publishTimer != null)
		{
			_publishTimer.WaitTime = Math.Max(1.0, CadenceSeconds);
			return;
		}

		_publishTimer = new Timer
		{
			Name = "DemoDataPublishTimer",
			Autostart = false,
			OneShot = false,
			WaitTime = Math.Max(1.0, CadenceSeconds),
		};
		AddChild(_publishTimer);
		_publishTimer.Timeout += OnPublishTimerTimeout;
	}

	private void OnBusRunningStateChanged(bool isRunning)
	{
		if (isRunning)
			Resume();
		else
			Pause();
	}

	private void OnPublishTimerTimeout()
	{
		PublishAllTopics();
	}

	private void PublishAllTopics()
	{
		if (_messageBus == null || !_messageBus.IsRunning)
			return;

		_phase += 0.35;
		_tick++;

		PublishChartPayload("bar", BuildBarData());
		PublishChartPayload("line", BuildLineData());
		PublishChartPayload("scatter", BuildScatterData());
		PublishChartPayload("histogram", BuildHistogramData());
		PublishChartPayload("surface", BuildSurfaceData());
		PublishChartPayload("graph_network", BuildGraphNetworkData());
	}

	private void PublishChartPayload(string chartType, GDDict data)
	{
		if (_messageBus == null)
			return;

		var topic = $"demo/stream/{chartType}";
		var payload = new GDDict
		{
			{ "schema_version", SchemaVersion },
			{ "topic", topic },
			{ "chart_type", chartType },
			{ "timestamp", Time.GetDatetimeStringFromSystem(true) },
			{ "data", data },
			{ "style", BuildStyle(chartType) },
			{ "meta", new GDDict { { "source", "DemoDataGenerator" }, { "tick", (long)_tick } } },
		};

		_messageBus.Publish(topic, payload);
	}

	private GDDict BuildStyle(string chartType)
	{
		var color = chartType switch
		{
			"bar" => "#2D9CDB",
			"line" => "#27AE60",
			"scatter" => "#EB5757",
			"histogram" => "#F2994A",
			"surface" => "#9B51E0",
			"graph_network" => "#56CCF2",
			_ => "#CCCCCC",
		};

		return new GDDict
		{
			{ "color", color },
			{ "texture", default(Variant) },
		};
	}

	private GDDict BuildBarData()
	{
		var baseSeries = new[] { 8.0, 10.0, 12.0, 14.0 };
		var values = new GDArray();
		for (var i = 0; i < baseSeries.Length; i++)
		{
			var noise = (_rng.NextDouble() - 0.5) * 1.5;
			var wave = Math.Sin(_phase + i * 0.6) * 1.2;
			values.Add(baseSeries[i] + wave + noise);
		}

		return new GDDict
		{
			{ "labels", new GDArray { "Q1", "Q2", "Q3", "Q4" } },
			{ "datasets", new GDArray { new GDDict { { "name", "Revenue" }, { "values", values } } } },
		};
	}

	private GDDict BuildLineData()
	{
		var points = new GDArray();
		for (var i = 0; i < 8; i++)
		{
			var x = i;
			var y = 9.5 + Math.Sin(_phase + i * 0.35) * 1.4 + (_rng.NextDouble() - 0.5) * 0.35;
			points.Add(new GDDict { { "x", x }, { "y", y }, { "z", 0.0 } });
		}

		return new GDDict
		{
			{ "datasets", new GDArray { new GDDict { { "name", "LatencyMs" }, { "points", points } } } },
		};
	}

	private GDDict BuildScatterData()
	{
		var points = new GDArray();
		for (var i = 0; i < 16; i++)
		{
			var x = i * 0.18;
			var y = 1.2 + Math.Sin(_phase + i * 0.4) * 0.6 + (_rng.NextDouble() - 0.5) * 0.2;
			var z = 0.3 + Math.Cos(_phase + i * 0.25) * 0.4 + (_rng.NextDouble() - 0.5) * 0.2;
			points.Add(new GDDict { { "x", x }, { "y", y }, { "z", z } });
		}

		return new GDDict
		{
			{ "datasets", new GDArray { new GDDict { { "name", "ClusterA" }, { "points", points } } } },
		};
	}

	private GDDict BuildHistogramData()
	{
		var counts = new GDArray();
		for (var i = 0; i < 6; i++)
		{
			var baseline = 8.0 + i * 1.4;
			var oscillation = Math.Sin(_phase + i * 0.45) * 2.0;
			var jitter = (_rng.NextDouble() - 0.5) * 2.0;
			counts.Add(Math.Max(0, (int)Math.Round(baseline + oscillation + jitter)));
		}

		return new GDDict
		{
			{ "name", "Count" },
			{ "bin_edges", new GDArray { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0 } },
			{ "counts", counts },
			{ "binning", new GDDict { { "mode", "auto" }, { "rule", "freedman_diaconis" }, { "fallback", "sturges" } } },
		};
	}

	private GDDict BuildSurfaceData()
	{
		const int rows = 8;
		const int cols = 8;
		var values = new GDArray();
		for (var z = 0; z < rows; z++)
		{
			var row = new GDArray();
			for (var x = 0; x < cols; x++)
			{
				var fx = x / (double)(cols - 1);
				var fz = z / (double)(rows - 1);
				var value = 0.55 + 0.40 * Math.Sin((_phase + fx * Math.PI * 2.0) * 1.2) * Math.Cos(_phase * 0.6 + fz * Math.PI * 2.0);
				row.Add(value);
			}
			values.Add(row);
		}

		return new GDDict
		{
			{ "x_labels", BuildNumericLabels(cols) },
			{ "z_labels", BuildNumericLabels(rows) },
			{ "values", values },
		};
	}

	private GDDict BuildGraphNetworkData()
	{
		var nodes = new GDArray();
		var nodeIds = new[] { "n1", "n2", "n3", "n4", "n5" };
		for (var i = 0; i < nodeIds.Length; i++)
		{
			var angle = (Math.PI * 2.0 * i / nodeIds.Length) + _phase * 0.15;
			var radius = 0.7 + (_rng.NextDouble() - 0.5) * 0.2;
			nodes.Add(new GDDict
			{
				{ "id", nodeIds[i] },
				{ "label", $"Node-{i + 1}" },
				{ "x", Math.Cos(angle) * radius },
				{ "y", Math.Sin(angle * 1.3) * 0.35 },
				{ "z", Math.Sin(angle) * radius },
			});
		}

		var edges = new GDArray
		{
			new GDDict { { "from", "n1" }, { "to", "n2" }, { "weight", 0.5 + _rng.NextDouble() * 0.5 } },
			new GDDict { { "from", "n1" }, { "to", "n3" }, { "weight", 0.5 + _rng.NextDouble() * 0.5 } },
			new GDDict { { "from", "n2" }, { "to", "n4" }, { "weight", 0.5 + _rng.NextDouble() * 0.5 } },
			new GDDict { { "from", "n3" }, { "to", "n5" }, { "weight", 0.5 + _rng.NextDouble() * 0.5 } },
		};

		return new GDDict
		{
			{ "nodes", nodes },
			{ "edges", edges },
		};
	}

	private static GDArray BuildNumericLabels(int count)
	{
		var labels = new GDArray();
		for (var i = 0; i < count; i++)
			labels.Add(i.ToString());
		return labels;
	}
}
