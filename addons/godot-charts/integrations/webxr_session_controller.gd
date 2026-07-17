class_name WebXrSessionController
extends RefCounted

signal state_changed(snapshot: Dictionary)

enum State { UNAVAILABLE, CHECKING, READY, STARTING, ACTIVE, FAILED }

var state := State.UNAVAILABLE
var available := false
var immersive_vr_supported := false
var reference_space_type := ""
var enabled_features := ""
var last_error := ""

var _interface: Variant
var _set_xr_enabled: Callable


func discover(set_xr_enabled: Callable = Callable(), interface_override: Variant = null) -> bool:
	_set_xr_enabled = set_xr_enabled
	_interface = interface_override if interface_override != null else XRServer.find_interface("WebXR")
	if _interface == null:
		_set_state(State.UNAVAILABLE, "WebXR is unavailable; flat-web mode remains active.")
		return false
	available = true
	_connect_interface()
	_set_state(State.CHECKING)
	_interface.is_session_supported("immersive-vr")
	return true


func request_session() -> bool:
	if state != State.READY or not immersive_vr_supported or _interface == null:
		return false
	_interface.session_mode = "immersive-vr"
	_interface.required_features = "local-floor"
	_interface.optional_features = "bounded-floor,hand-tracking"
	_interface.requested_reference_space_types = "bounded-floor,local-floor,local"
	_set_state(State.STARTING)
	if not _interface.initialize():
		_on_session_failed("WebXR initialization was rejected before session startup.")
		return false
	return true


func end_session() -> bool:
	if state != State.ACTIVE or _interface == null:
		return false
	_interface.uninitialize()
	_on_session_ended()
	return true


func snapshot() -> Dictionary:
	return {
		"state": State.keys()[state].to_lower(),
		"available": available,
		"immersive_vr_supported": immersive_vr_supported,
		"reference_space_type": reference_space_type,
		"enabled_features": enabled_features,
		"last_error": last_error,
	}


func interface_handle() -> Variant:
	return _interface


func _connect_interface() -> void:
	_connect_once("session_supported", _on_session_supported)
	_connect_once("session_started", _on_session_started)
	_connect_once("session_ended", _on_session_ended)
	_connect_once("session_failed", _on_session_failed)


func _connect_once(signal_name: StringName, callback: Callable) -> void:
	if _interface.has_signal(signal_name) and not _interface.is_connected(signal_name, callback):
		_interface.connect(signal_name, callback)


func _on_session_supported(session_mode: String, supported: bool) -> void:
	if session_mode != "immersive-vr":
		return
	immersive_vr_supported = supported
	if supported:
		_set_state(State.READY)
	else:
		_set_state(State.UNAVAILABLE, "Immersive VR is not supported; flat-web mode remains active.")


func _on_session_started() -> void:
	reference_space_type = str(_interface.reference_space_type)
	enabled_features = str(_interface.enabled_features)
	if _set_xr_enabled.is_valid():
		_set_xr_enabled.call(true)
	_set_state(State.ACTIVE)


func _on_session_ended() -> void:
	if _set_xr_enabled.is_valid():
		_set_xr_enabled.call(false)
	reference_space_type = ""
	enabled_features = ""
	_set_state(State.READY if immersive_vr_supported else State.UNAVAILABLE)


func _on_session_failed(message: String) -> void:
	if _set_xr_enabled.is_valid():
		_set_xr_enabled.call(false)
	_set_state(State.FAILED, message if not message.is_empty() else "The immersive session failed to start.")


func _set_state(next_state: int, error := "") -> void:
	state = next_state
	last_error = error
	state_changed.emit(snapshot())
