class_name WebSocketSessionClient
extends Node

signal state_changed(state: State)
signal transport_diagnostic(diagnostic: Dictionary)
signal message_received(message: Dictionary)

enum State { DISCONNECTED, CONNECTING, OPEN, CLOSING, BACKOFF, FAILED }

@export var max_message_bytes: int = 1_048_576
@export var max_messages_per_poll: int = 32
@export var auto_reconnect: bool = false
@export var reconnect_initial_seconds: float = 0.5
@export var reconnect_max_seconds: float = 8.0

var state: State = State.DISCONNECTED
var received_messages: int = 0
var received_bytes: int = 0
var reconnect_attempts: int = 0
var diagnostics: Array[Dictionary] = []

var _peer: WebSocketPeer
var _replay: RefCounted
var _url: String = ""
var _safe_endpoint: String = ""
var _saw_handshake: bool = false
var _expected_session_id: String = ""
var _backoff_remaining: float = 0.0
var _next_backoff: float = 0.5


func connect_session(url: String, replay: RefCounted) -> Error:
	_close_peer(false)
	_url = url
	_safe_endpoint = _redact_endpoint(url)
	_replay = replay
	_saw_handshake = false
	_expected_session_id = ""
	received_messages = 0
	received_bytes = 0
	reconnect_attempts = 0
	diagnostics.clear()
	_next_backoff = reconnect_initial_seconds
	if _replay == null or not _replay.has_method("receive_message"):
		_fail("invalid-consumer", "Live transport requires a streaming protocol consumer.")
		return ERR_INVALID_PARAMETER
	_replay.begin_live()
	return _open()


func disconnect_session(code: int = 1000, reason: String = "client disconnect") -> void:
	auto_reconnect = false
	_close_peer(true, code, reason)


func _close_peer(complete_consumer: bool, code: int = 1000, reason: String = "client disconnect") -> void:
	if _peer != null and _peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_set_state(State.CLOSING)
		_peer.close(code, reason)
	_peer = null
	if complete_consumer and _replay != null and _replay.has_method("complete_live"):
		_replay.complete_live()
	_set_state(State.DISCONNECTED)


func poll_transport(delta: float = 0.0) -> void:
	if state == State.BACKOFF:
		_backoff_remaining -= delta
		if _backoff_remaining <= 0.0:
			reconnect_attempts += 1
			_saw_handshake = false
			_expected_session_id = ""
			_replay.begin_live()
			_open()
		return
	if _peer == null:
		return
	_peer.poll()
	var ready_state := _peer.get_ready_state()
	if _peer.get_available_packet_count() > 0:
		_drain_packets()
	if ready_state == WebSocketPeer.STATE_OPEN and state != State.OPEN:
		_set_state(State.OPEN)
	if ready_state == WebSocketPeer.STATE_CLOSED:
		var close_code := _peer.get_close_code()
		var close_reason := _peer.get_close_reason()
		_peer = null
		if _replay != null and _replay.has_method("complete_live"):
			_replay.complete_live()
		if auto_reconnect:
			_backoff_remaining = _next_backoff
			_next_backoff = minf(_next_backoff * 2.0, reconnect_max_seconds)
			_set_state(State.BACKOFF)
		else:
			_set_state(State.DISCONNECTED)
		if close_code != 1000 and close_code != -1:
			_report("warning", "remote-close", "WebSocket closed with code %d: %s" % [close_code, close_reason])


func snapshot() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"endpoint": _safe_endpoint,
		"received_messages": received_messages,
		"received_bytes": received_bytes,
		"reconnect_attempts": reconnect_attempts,
		"handshake_received": _saw_handshake,
		"session_id": _expected_session_id,
		"diagnostics": diagnostics.duplicate(true),
	}


func _process(delta: float) -> void:
	poll_transport(delta)


func _open() -> Error:
	_peer = WebSocketPeer.new()
	_peer.max_queued_packets = max_messages_per_poll * 2
	var error := _peer.connect_to_url(_url)
	if error != OK:
		_peer = null
		_fail("connection-failed", "Could not start WebSocket connection to %s." % _safe_endpoint)
		return error
	_set_state(State.CONNECTING)
	return OK


func _drain_packets() -> void:
	var processed := 0
	while _peer.get_available_packet_count() > 0 and processed < max_messages_per_poll:
		processed += 1
		var packet := _peer.get_packet()
		if not _peer.was_string_packet():
			_report("error", "binary-message", "Binary WebSocket messages are not supported.")
			continue
		if packet.size() > max_message_bytes:
			_report("error", "message-too-large", "WebSocket message exceeds the configured byte limit.")
			continue
		var value: Variant = JSON.parse_string(packet.get_string_from_utf8())
		if not value is Dictionary:
			_report("error", "invalid-json", "WebSocket message must be a JSON object.")
			continue
		var message: Dictionary = value
		if not _accept_session_message(message):
			continue
		received_messages += 1
		received_bytes += packet.size()
		message_received.emit(message.duplicate(true))
		_replay.receive_message(message)


func _accept_session_message(message: Dictionary) -> bool:
	if not _saw_handshake:
		if message.get("schema", "") != "godot-charts/session-handshake/1.0":
			_report("error", "handshake-required", "The first live message must be a session handshake.")
			return false
		_expected_session_id = str(message.get("session_id", ""))
		_saw_handshake = true
		return true
	if str(message.get("session_id", "")) != _expected_session_id:
		_report("error", "session-mismatch", "Message does not belong to the negotiated session.")
		return false
	return true


func _set_state(next_state: State) -> void:
	if state == next_state:
		return
	state = next_state
	state_changed.emit(state)


func _fail(code: String, message: String) -> void:
	_report("error", code, message)
	_set_state(State.FAILED)


func _report(severity: String, code: String, message: String) -> void:
	var diagnostic := {"severity": severity, "code": code, "message": message, "path": "/transport"}
	diagnostics.append(diagnostic)
	transport_diagnostic.emit(diagnostic.duplicate(true))


func _redact_endpoint(url: String) -> String:
	var parsed := url.split("?", true, 1)[0]
	var scheme_separator := parsed.find("://")
	if scheme_separator < 0:
		return "<invalid-endpoint>"
	var scheme := parsed.substr(0, scheme_separator)
	var authority := parsed.substr(scheme_separator + 3).split("/", true, 1)[0]
	if "@" in authority:
		authority = authority.split("@", true, 1)[1]
	return "%s://%s" % [scheme, authority]
