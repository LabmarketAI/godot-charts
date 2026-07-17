extends SceneTree

const Client = preload("res://addons/godot-charts/integrations/websocket_session_client.gd")
const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const ScatterRenderer = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const TableView = preload("res://addons/godot-charts/tables/bounded_table_view.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameView = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const Controller = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var port := int(OS.get_environment("GODOT_CHARTS_LIVE_PORT"))
	_assert(port > 0, "fixture server port is provided")
	var manifest := _load_json("res://tests/m1/fixtures/replay-manifest.json")
	var replay = Replay.new()
	var frame = FrameView.new()
	var renderer = ScatterRenderer.new()
	var table = TableView.new()
	root.add_child(frame)
	root.add_child(table)
	_assert(frame.bind_content(renderer, table), "live scatter binds through public frame port")
	var frame_state = FrameState.new("live-frame", Transform3D.IDENTITY, Vector3(6.0, 4.0, 3.0), "Live frame")
	_assert(frame.apply_frame_state(frame_state), "live frame state applies")
	var controller = Controller.new()
	_assert(controller.bind(frame_state, frame), "live frame controller binds")
	controller.set_mode("frame")
	controller.set_selected(true)
	_assert(controller.begin("move", "test") and controller.preview_move(Vector3(2.0, 1.0, -1.0), "test") and controller.commit("test"), "user moves frame before live delivery")
	controller.set_mode("navigate")
	_assert(controller.update_navigation({"orbit": [0.1, 0.4, 0.0]}), "user navigation state applies before live delivery")
	var preserved_frame_state: Dictionary = frame_state.to_dictionary()
	var preserved_lifecycle: Dictionary = frame.lifecycle_snapshot()
	var session = Session.new()
	session.bind(replay, frame, table)
	var client = Client.new()
	root.add_child(client)
	client.auto_reconnect = true
	client.reconnect_initial_seconds = 0.01
	client.reconnect_max_seconds = 0.01
	var error := client.connect_session("ws://127.0.0.1:%d/fixture?secret=redacted" % port, replay)
	_assert(error == OK, "WebSocket connection starts")
	var deadline := Time.get_ticks_msec() + 10_000
	var revision_one_render_node := 0
	var revision_one_resource := 0
	var expected_received: int = manifest["messages"].size() * 2
	while client.state != client.State.FAILED and Time.get_ticks_msec() < deadline:
		await process_frame
		if session.active_revision == 1 and revision_one_render_node == 0:
			revision_one_render_node = renderer.render_node().get_instance_id()
			revision_one_resource = renderer.render_resource().get_instance_id()
		if client.reconnect_attempts == 1 and client.received_messages >= expected_received:
			client.disconnect_session()
			break
	print("Live transport snapshot: ", client.snapshot(), " replay_applied=", replay.applied_messages)
	_assert(Time.get_ticks_msec() < deadline, "live fixture completes before timeout")
	_assert(client.state == client.State.DISCONNECTED, "normal server close disconnects the client")
	_assert(client.diagnostics.is_empty(), "valid transport has no diagnostics")
	_assert(client.received_messages == expected_received, "all envelopes arrive across initial and reconnected sessions")
	_assert(client.reconnect_attempts == 1, "transport completes exactly one automatic reconnect")
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
	_assert(frame_state.to_dictionary() == preserved_frame_state, "live replacement preserves frame transform and local view state")
	_assert(revision_one_render_node != 0 and renderer.render_node().get_instance_id() == revision_one_render_node, "live compatible revision preserves framed render node")
	_assert(renderer.render_resource().get_instance_id() == revision_one_resource, "live compatible revision preserves framed render resource")
	_assert(Array(session.linked_selection.row_ids) == manifest["expected"]["preserved_row_ids"], "live framed selection remains eligible")
	_assert(not frame.primitive_id_for_row(manifest["expected"]["preserved_row_ids"][0]).is_empty(), "live framed picking identity remains resolvable")
	var final_lifecycle: Dictionary = frame.lifecycle_snapshot()
	for key: String in ["frame_node", "content_root", "guide_root", "chrome_root", "handle_root", "bounds_node", "bounds_mesh", "child_count", "content_child_count"]:
		_assert(final_lifecycle[key] == preserved_lifecycle[key], "live transport preserves frame lifecycle: " + key)
	client.queue_free()
	table.queue_free()
	frame.queue_free()
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
