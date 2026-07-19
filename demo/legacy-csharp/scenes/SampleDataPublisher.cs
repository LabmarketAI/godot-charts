// SampleDataPublisher — headless WebSocket server that emits rotating canned datasets.
//
// Run as a separate process alongside the VR/desktop scene:
//   godot --headless --path demo --scene res://scenes/publisher.tscn
//
// The scene connects on ws://localhost:<port> (default 7780).
// Dataset variants are loaded from demo/data/publisher/*.json — edit those files
// to craft data for maximum visual effect without recompiling.
//
// Wire format (one JSON text frame per emission):
//   { "topic": "demo/stream/<type>", "payload": { "chart_type": "<type>", "data": { ... } } }

using System;
using System.Collections.Generic;
using System.Text;
using Godot;
using Godot.Collections;

public partial class SampleDataPublisher : Node
{
	private const string ConfigPath = "res://data/publisher/_config.json";
	private const string DataDir    = "res://data/publisher/";

	private int    _port       = 7780;
	private double _intervalMs = 700.0;
	private readonly List<string> _enabledTypes = new();

	// Per-chart-type: list of dataset variant dicts, current index.
	private readonly System.Collections.Generic.Dictionary<string, List<Godot.Collections.Dictionary>> _variants = new();
	private readonly System.Collections.Generic.Dictionary<string, int> _variantIndex = new();

	private TcpServer  _tcpServer  = new();
	private readonly List<WebSocketPeer> _clients = new();

	private double _accumulator;
	private int    _tickCount;

	public override void _Ready()
	{
		LoadConfig();
		LoadDatasets();
		StartServer();
	}

	public override void _Process(double delta)
	{
		AcceptNewClients();
		PollClients();

		_accumulator += delta * 1000.0;
		if (_accumulator >= _intervalMs)
		{
			_accumulator -= _intervalMs;
			Emit();
		}
	}

	// ── Config ──────────────────────────────────────────────────────────────

	private void LoadConfig()
	{
		if (!FileAccess.FileExists(ConfigPath))
		{
			GD.Print($"[Publisher] No _config.json at {ConfigPath} — using defaults.");
			_enabledTypes.AddRange(new[] { "bar", "line", "scatter", "surface", "histogram", "network" });
			return;
		}

		using var f = FileAccess.Open(ConfigPath, FileAccess.ModeFlags.Read);
		var parsed = Json.ParseString(f.GetAsText());
		if (parsed.VariantType != Variant.Type.Dictionary)
			return;

		var cfg = parsed.AsGodotDictionary();
		if (cfg.TryGetValue("port",        out var portVar))  _port       = portVar.AsInt32();
		if (cfg.TryGetValue("interval_ms", out var intVar))   _intervalMs = intVar.AsDouble();

		if (cfg.TryGetValue("enabled_types", out var typesVar) && typesVar.VariantType == Variant.Type.Array)
		{
			foreach (var t in typesVar.AsGodotArray())
				_enabledTypes.Add(t.AsString());
		}
		else
		{
			_enabledTypes.AddRange(new[] { "bar", "line", "scatter", "surface", "histogram", "network" });
		}

		GD.Print($"[Publisher] Config: port={_port} interval={_intervalMs}ms types=[{string.Join(", ", _enabledTypes)}]");
	}

	// ── Dataset loading ──────────────────────────────────────────────────────

	private void LoadDatasets()
	{
		foreach (var chartType in _enabledTypes)
		{
			var path = DataDir + chartType + ".json";
			if (!FileAccess.FileExists(path))
			{
				GD.PushWarning($"[Publisher] Dataset file not found: {path} — skipping {chartType}");
				continue;
			}

			using var f = FileAccess.Open(path, FileAccess.ModeFlags.Read);
			var parsed = Json.ParseString(f.GetAsText());
			if (parsed.VariantType != Variant.Type.Dictionary)
			{
				GD.PushWarning($"[Publisher] Failed to parse {path}");
				continue;
			}

			var root = parsed.AsGodotDictionary();
			if (!root.TryGetValue("datasets", out var datasetsVar) || datasetsVar.VariantType != Variant.Type.Array)
			{
				GD.PushWarning($"[Publisher] No 'datasets' array in {path}");
				continue;
			}

			var list = new List<Godot.Collections.Dictionary>();
			foreach (var item in datasetsVar.AsGodotArray())
			{
				if (item.VariantType == Variant.Type.Dictionary)
					list.Add(item.AsGodotDictionary());
			}

			if (list.Count == 0)
			{
				GD.PushWarning($"[Publisher] Empty datasets in {path}");
				continue;
			}

			_variants[chartType]     = list;
			_variantIndex[chartType] = 0;
			GD.Print($"[Publisher] Loaded {list.Count} variant(s) for {chartType}");
		}
	}

	// ── WebSocket server ─────────────────────────────────────────────────────

	private void StartServer()
	{
		var err = _tcpServer.Listen((ushort)_port);
		if (err != Error.Ok)
		{
			GD.PushError($"[Publisher] Failed to listen on port {_port}: {err}");
			return;
		}
		GD.Print($"[Publisher] Listening on ws://localhost:{_port} — waiting for subscribers.");
	}

	private void AcceptNewClients()
	{
		if (!_tcpServer.IsListening() || !_tcpServer.IsConnectionAvailable())
			return;

		var stream = _tcpServer.TakeConnection();
		var ws     = new WebSocketPeer();
		var err    = ws.AcceptStream(stream);
		if (err != Error.Ok)
		{
			GD.PushWarning($"[Publisher] Failed to accept WebSocket connection: {err}");
			return;
		}

		_clients.Add(ws);
		GD.Print($"[Publisher] Client connected — total: {_clients.Count}");
	}

	private void PollClients()
	{
		for (var i = _clients.Count - 1; i >= 0; i--)
		{
			_clients[i].Poll();
			var state = _clients[i].GetReadyState();
			if (state == WebSocketPeer.State.Closed)
			{
				_clients.RemoveAt(i);
				GD.Print($"[Publisher] Client disconnected — total: {_clients.Count}");
			}
		}
	}

	// ── Emission ─────────────────────────────────────────────────────────────

	private void Emit()
	{
		_tickCount++;
		if (_clients.Count == 0)
			return;

		foreach (var chartType in _enabledTypes)
		{
			if (!_variants.TryGetValue(chartType, out var list) || list.Count == 0)
				continue;

			var idx     = _variantIndex[chartType];
			var data    = list[idx];
			_variantIndex[chartType] = (idx + 1) % list.Count;

			var json = BuildWireMessage(chartType, data);
			var bytes = Encoding.UTF8.GetBytes(json);
			var packet = new byte[bytes.Length];
			bytes.CopyTo(packet, 0);

			foreach (var client in _clients)
			{
				if (client.GetReadyState() == WebSocketPeer.State.Open)
					client.PutPacket(packet);
			}
		}

		if (_tickCount % 10 == 0)
			GD.Print($"[Publisher] Tick {_tickCount} — {_clients.Count} client(s) connected.");
	}

	private static string BuildWireMessage(string chartType, Godot.Collections.Dictionary data)
	{
		// Strip the "comment" key before sending — it's for human editors, not the subscriber.
		var payload = new Godot.Collections.Dictionary();
		foreach (var key in data.Keys)
		{
			if (key.AsString() == "comment")
				continue;
			payload[key] = data[key];
		}

		var envelope = new Godot.Collections.Dictionary
		{
			{ "topic",   $"demo/stream/{chartType}" },
			{ "payload", new Godot.Collections.Dictionary
				{
					{ "chart_type", chartType },
					{ "data",       payload   },
				}
			},
		};

		return Json.Stringify(envelope);
	}

	public override void _ExitTree()
	{
		foreach (var client in _clients)
			client.Close();
		_clients.Clear();
		_tcpServer.Stop();
	}
}
