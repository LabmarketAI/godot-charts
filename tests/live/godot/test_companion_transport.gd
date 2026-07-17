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
	var replay = Replay.new()
	var renderer = ScatterRenderer.new()
	var table = TableView.new()
	root.add_child(renderer)
	root.add_child(table)
	var session = Session.new()
	session.bind(replay, renderer, table)
	var client = Client.new()
	root.add_child(client)
	var port := int(OS.get_environment("GODOT_CHARTS_LIVE_PORT"))
	_assert(client.connect_session("ws://127.0.0.1:%d" % port, replay) == OK, "companion connection starts")
	var deadline := Time.get_ticks_msec() + 10_000
	while client.state != client.State.DISCONNECTED and client.state != client.State.FAILED and Time.get_ticks_msec() < deadline:
		await process_frame
	_assert(Time.get_ticks_msec() < deadline, "companion session completes")
	_assert(client.diagnostics.is_empty(), "companion transport has no diagnostics")
	_assert(client.received_messages == 2 and replay.applied_messages == 2, "handshake and plot apply")
	_assert(session.active_revision == 1, "companion plot installs revision one")
	_assert(session.active_figure.id == "figure-plot-companion-live", "companion figure identity arrives")
	_assert(renderer.rendered_point_count() == 3, "companion DataFrame renders three points")
	_assert(table.displayed_row_count() == 3, "companion DataFrame renders three table rows")
	_assert(renderer.resolve_primitive(renderer.primitive_id_for_row("trial-live-2023"))["values"]["phase"] == "II", "stable row inspection survives transport")
	client.queue_free()
	table.queue_free()
	renderer.queue_free()
	if _failures == 0:
		print("Godot Charts companion-to-Godot test passed.")
		quit(0)
	else:
		push_error("Companion-to-Godot test failed: %d assertion(s)." % _failures)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
