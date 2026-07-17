extends SceneTree

const Client = preload("res://addons/godot-charts/integrations/websocket_session_client.gd")
const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const ScatterRenderer = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const TableView = preload("res://addons/godot-charts/tables/bounded_table_view.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var port := int(OS.get_environment("GODOT_CHARTS_LIVE_PORT"))
	_assert(port > 0, "fixture server port is provided")
	var manifest := _load_json("res://tests/m1/fixtures/replay-manifest.json")
	var replay = Replay.new()
	var renderer = ScatterRenderer.new()
	var table = TableView.new()
	root.add_child(renderer)
	root.add_child(table)
	var session = Session.new()
	session.bind(replay, renderer, table)
	var client = Client.new()
	root.add_child(client)
	var error := client.connect_session("ws://127.0.0.1:%d/fixture?secret=redacted" % port, replay)
	_assert(error == OK, "WebSocket connection starts")
	var deadline := Time.get_ticks_msec() + 10_000
	while client.state != client.State.DISCONNECTED and client.state != client.State.FAILED and Time.get_ticks_msec() < deadline:
		await process_frame
	print("Live transport snapshot: ", client.snapshot(), " replay_applied=", replay.applied_messages)
	_assert(Time.get_ticks_msec() < deadline, "live fixture completes before timeout")
	_assert(client.state == client.State.DISCONNECTED, "normal server close disconnects the client")
	_assert(client.diagnostics.is_empty(), "valid transport has no diagnostics")
	_assert(client.received_messages == manifest["messages"].size(), "all live envelopes arrive")
	_assert(client.snapshot()["endpoint"] == "ws://127.0.0.1:%d" % port, "trace endpoint redacts path and query")
	_assert(client.snapshot()["handshake_received"], "transport negotiates a handshake first")
	_assert(replay.status == replay.Status.COMPLETE, "remote close completes the live consumer")
	_assert(replay.applied_messages == manifest["expected"]["applied_messages"], "live and recorded applied counts match")
	_assert(replay.duplicate_messages == manifest["expected"]["duplicate_messages"], "live duplicate handling matches replay")
	_assert(replay.active_plot_revision == manifest["expected"]["active_plot_revision"], "live replacement reaches expected revision")
	_assert(Array(replay.selection_row_ids) == manifest["expected"]["preserved_row_ids"], "live selection preservation matches replay")
	_assert(session.active_revision == manifest["expected"]["active_plot_revision"], "live messages drive the shared plot session")
	_assert(renderer.rendered_point_count() == 4, "live plot drives the shared scatter renderer")
	_assert(table.displayed_row_count() == 5, "live plot drives the shared bounded table")
	client.queue_free()
	table.queue_free()
	renderer.queue_free()
	if _failures == 0:
		print("Godot Charts live WebSocket transport test passed.")
		quit(0)
	else:
		push_error("Live WebSocket transport test failed: %d assertion(s)." % _failures)
		quit(1)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "fixture opens: " + path)
	var value: Variant = JSON.parse_string(file.get_as_text())
	_assert(value is Dictionary, "fixture parses: " + path)
	return value


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
