// WebSocketBridgeService — connects to the SampleDataPublisher and forwards
// received messages into the in-process MessageBusService.
//
// Add as a child of MainVr or Main. It auto-connects on _Ready and silently
// retries every RetryIntervalSeconds when the publisher is not running.
// Existing DemoDataGenerator stream continues unaffected when disconnected.

using System.Text;
using Godot;
using Godot.Collections;

public partial class WebSocketBridgeService : Node
{
	[Export] public string Host               { get; set; } = "ws://localhost:7780";
	[Export] public float  RetryIntervalSeconds { get; set; } = 5.0f;

	[Signal]
	public delegate void ConnectionStateChangedEventHandler(bool connected);

	public new bool IsConnected => _ws.GetReadyState() == WebSocketPeer.State.Open;

	private WebSocketPeer  _ws        = new();
	private MessageBusService? _bus;
	private double _retryAccumulator;
	private bool   _wasConnected;

	public void BindMessageBus(MessageBusService bus) => _bus = bus;

	public override void _Ready()
	{
		TryConnect();
	}

	public override void _Process(double delta)
	{
		_ws.Poll();

		var state = _ws.GetReadyState();

		// Fire signal on state change.
		var nowConnected = state == WebSocketPeer.State.Open;
		if (nowConnected != _wasConnected)
		{
			_wasConnected = nowConnected;
			EmitSignal(SignalName.ConnectionStateChanged, nowConnected);
			GD.Print(nowConnected
				? $"[Bridge] Connected to publisher at {Host}"
				: $"[Bridge] Disconnected from publisher.");
		}

		// Drain incoming packets and forward to bus.
		while (state == WebSocketPeer.State.Open && _ws.GetAvailablePacketCount() > 0)
		{
			var raw    = _ws.GetPacket();
			var text   = Encoding.UTF8.GetString(raw);
			HandleMessage(text);
		}

		// Retry when closed.
		if (state == WebSocketPeer.State.Closed)
		{
			_retryAccumulator += delta;
			if (_retryAccumulator >= RetryIntervalSeconds)
			{
				_retryAccumulator = 0.0;
				TryConnect();
			}
		}
	}

	private void TryConnect()
	{
		_ws = new WebSocketPeer();
		var err = _ws.ConnectToUrl(Host);
		if (err != Error.Ok)
			GD.Print($"[Bridge] Could not initiate connection to {Host} (publisher may not be running): {err}");
	}

	private void HandleMessage(string text)
	{
		if (_bus == null || string.IsNullOrWhiteSpace(text))
			return;

		var parsed = Json.ParseString(text);
		if (parsed.VariantType != Variant.Type.Dictionary)
			return;

		var envelope = parsed.AsGodotDictionary();
		if (!envelope.TryGetValue("topic",   out var topicVar)   || topicVar.VariantType   != Variant.Type.String)
			return;
		if (!envelope.TryGetValue("payload", out var payloadVar) || payloadVar.VariantType != Variant.Type.Dictionary)
			return;

		_bus.Publish(topicVar.AsString(), payloadVar.AsGodotDictionary());
	}

	public override void _ExitTree()
	{
		_ws.Close();
	}
}
