using System;
using System.Collections.Generic;
using Godot;
using Godot.Collections;

public partial class MessageBusService : Node
{
	[Signal]
	public delegate void MessageReceivedEventHandler(string topic, Dictionary payload);

	[Signal]
	public delegate void RunningStateChangedEventHandler(bool isRunning);

	private const double DefaultHeartbeatSeconds = 30.0;
	private const string HeartbeatTopic = "bus/status";

	private readonly System.Collections.Generic.Dictionary<string, HashSet<string>> _subscriberIdsByTopic = new();
	private Timer? _heartbeatTimer;
	private ulong _heartbeatTick;

	public bool IsRunning { get; private set; }

	public override void _Ready()
	{
		EnsureHeartbeatTimer(DefaultHeartbeatSeconds);
		Start();
	}

	public void ConfigureHeartbeat(double intervalSeconds, bool restartIfRunning = true)
	{
		if (intervalSeconds <= 0.0)
			intervalSeconds = DefaultHeartbeatSeconds;

		EnsureHeartbeatTimer(intervalSeconds);
		if (restartIfRunning && IsRunning)
			_heartbeatTimer?.Start();
	}

	public void Start()
	{
		if (IsRunning)
			return;

		IsRunning = true;
		_heartbeatTimer?.Start();
		EmitSignal(SignalName.RunningStateChanged, IsRunning);
	}

	public void Stop()
	{
		if (!IsRunning)
			return;

		IsRunning = false;
		_heartbeatTimer?.Stop();
		EmitSignal(SignalName.RunningStateChanged, IsRunning);
	}

	public bool Publish(string topic, Dictionary payload)
	{
		if (!IsRunning || string.IsNullOrWhiteSpace(topic))
			return false;

		EmitSignal(SignalName.MessageReceived, topic, payload);
		return true;
	}

	// DataBindingService and future consumers can register interest by topic.
	public void RegisterSubscriber(string topic, string subscriberId)
	{
		if (string.IsNullOrWhiteSpace(topic) || string.IsNullOrWhiteSpace(subscriberId))
			return;

		if (!_subscriberIdsByTopic.TryGetValue(topic, out var subscribers))
		{
			subscribers = new HashSet<string>(StringComparer.Ordinal);
			_subscriberIdsByTopic[topic] = subscribers;
		}

		subscribers.Add(subscriberId);
	}

	public void UnregisterSubscriber(string topic, string subscriberId)
	{
		if (string.IsNullOrWhiteSpace(topic) || string.IsNullOrWhiteSpace(subscriberId))
			return;

		if (!_subscriberIdsByTopic.TryGetValue(topic, out var subscribers))
			return;

		subscribers.Remove(subscriberId);
		if (subscribers.Count == 0)
			_subscriberIdsByTopic.Remove(topic);
	}

	public int GetSubscriberCount(string topic)
	{
		if (string.IsNullOrWhiteSpace(topic))
			return 0;
		return _subscriberIdsByTopic.TryGetValue(topic, out var subscribers) ? subscribers.Count : 0;
	}

	public Array<string> ListTopics()
	{
		var topics = new Array<string>();
		foreach (var topic in _subscriberIdsByTopic.Keys)
			topics.Add(topic);
		return topics;
	}

	private void EnsureHeartbeatTimer(double intervalSeconds)
	{
		if (_heartbeatTimer == null)
		{
			_heartbeatTimer = new Timer
			{
				Name = "HeartbeatTimer",
				OneShot = false,
				Autostart = false,
			};
			AddChild(_heartbeatTimer);
			_heartbeatTimer.Timeout += OnHeartbeatTimeout;
		}

		_heartbeatTimer.WaitTime = intervalSeconds;
	}

	private void OnHeartbeatTimeout()
	{
		if (!IsRunning)
			return;

		_heartbeatTick++;
		var payload = new Dictionary
		{
			{ "schema_version", "1.0" },
			{ "service", "MessageBusService" },
			{ "kind", "heartbeat" },
			{ "tick", (long)_heartbeatTick },
			{ "timestamp", Time.GetDatetimeStringFromSystem(true) },
		};

		EmitSignal(SignalName.MessageReceived, HeartbeatTopic, payload);
	}
}
