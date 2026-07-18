extends SceneTree

const Binding = preload("res://addons/godot-charts/frames/frame_binding.gd")
const FrameState = preload("res://addons/godot-charts/frames/analytical_frame_state.gd")
const FrameView = preload("res://addons/godot-charts/renderers/analytical_frame_3d.gd")
const Guides = preload("res://addons/godot-charts/renderers/cartesian_guides_3d.gd")
const Ticks = preload("res://addons/godot-charts/core/linear_ticks.gd")
const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const Scatter = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const TableView = preload("res://addons/godot-charts/tables/bounded_table_view.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const Diagnostics = preload("res://addons/godot-charts/diagnostics/plot_diagnostics.gd")
const FrameInteraction = preload("res://addons/godot-charts/interactions/frame_interaction_controller.gd")
const AxisDomainInteraction = preload("res://addons/godot-charts/interactions/axis_domain_interaction_controller.gd")

var _failures := 0


func _initialize() -> void:
	var binding = Binding.new("live_plot", "plot-annual-trials", "follow_source", 2, {"transport": "websocket"})
	_assert(binding.validate().is_empty(), "valid live binding passes")
	var authored := Transform3D(Basis.from_euler(Vector3(0.1, 0.4, 0.0)).scaled(Vector3(1.2, 1.2, 1.2)), Vector3(2.0, 1.0, -3.0))
	var state = FrameState.new("frame-annual-trials", authored, Vector3(6.0, 4.0, 2.5), "Annual trials", binding)
	state.local_view_state = {"orientation": [0.2, 0.5, 0.0], "selected_view_id": "view-main"}
	_assert(state.validate().is_empty(), "valid frame state passes")
	_assert(state.binding.source_id == "plot-annual-trials", "frame retains binding identity")

	var encoded := state.to_dictionary()
	var decoded = FrameState.from_dictionary(encoded)
	_assert(decoded.validate().is_empty(), "round-tripped frame validates")
	_assert(decoded.to_dictionary() == encoded, "frame serialization round-trips deterministically")
	_assert(decoded.transform.is_equal_approx(authored), "frame transform round-trips")
	_assert(decoded.authored_transform.is_equal_approx(authored), "authored reset transform round-trips")
	_assert(decoded.binding.to_dictionary() == binding.to_dictionary(), "binding serialization round-trips")

	decoded.transform = Transform3D(Basis.IDENTITY, Vector3(9.0, 8.0, 7.0))
	decoded.local_view_state["orientation"] = [1.0, 1.0, 1.0]
	decoded.reset_to_authored()
	_assert(decoded.transform.is_equal_approx(authored), "reset restores exact authored transform")
	_assert(decoded.local_view_state.is_empty(), "reset clears local view overrides")
	decoded.transform = Transform3D(Basis.IDENTITY, Vector3(-2.0, 3.0, 4.0))
	decoded.capture_authored_state()
	decoded.transform = Transform3D.IDENTITY
	decoded.reset_to_authored()
	_assert(decoded.transform.origin.is_equal_approx(Vector3(-2.0, 3.0, 4.0)), "captured authored state becomes reset target")

	var invalid_binding = Binding.new("socket", "", "automatic", -1)
	var invalid_codes := _codes(invalid_binding.validate())
	_assert("invalid-binding-kind" in invalid_codes, "invalid binding kind is diagnosed")
	_assert("empty-binding-source" in invalid_codes, "empty binding source is diagnosed")
	_assert("invalid-representation-policy" in invalid_codes, "invalid representation policy is diagnosed")
	_assert("invalid-source-revision" in invalid_codes, "invalid source revision is diagnosed")
	var invalid_state = FrameState.new("", Transform3D.IDENTITY, Vector3(0.0, 2.0, 3.0), "", invalid_binding)
	invalid_state.source_status = "unknown"
	invalid_state.aspect_policy = "stretch-data"
	invalid_state.theme_ref = ""
	var invalid_frame_codes := _codes(invalid_state.validate())
	_assert("empty-frame-id" in invalid_frame_codes, "empty frame identity is diagnosed")
	_assert("invalid-frame-bounds" in invalid_frame_codes, "invalid frame bounds are diagnosed")
	_assert("invalid-source-status" in invalid_frame_codes, "invalid source status is diagnosed")
	_assert("invalid-aspect-policy" in invalid_frame_codes, "invalid aspect policy is diagnosed")
	_assert("empty-theme-reference" in invalid_frame_codes, "empty theme reference is diagnosed")
	_assert("invalid-binding-kind" in invalid_frame_codes, "binding diagnostics retain frame path")
	_assert(Ticks.generate(2021.0, 2025.0, 5) == [2021.0, 2022.0, 2023.0, 2024.0, 2025.0], "year ticks are deterministic")
	_assert(Ticks.generate(120.0, 250.0, 5) == [150.0, 200.0, 250.0], "nice enrollment ticks remain within domain")
	_assert(Ticks.format(0.25, 0.05) == "0.25" and Ticks.format(2024.0, 1.0) == "2024", "tick formatting follows deterministic precision")
	_assert(Ticks.generate(1.0, 1.0).is_empty(), "degenerate tick domain is rejected")

	var frame_view = FrameView.new()
	var scatter = Scatter.new()
	var guides = Guides.new()
	var table = TableView.new()
	root.add_child(frame_view)
	root.add_child(table)
	_assert(frame_view.bind_content(scatter, table), "frame binds public scatter and table ports")
	_assert(frame_view.bind_guide_renderer(guides), "frame binds guide renderer under stable guide root")
	_assert(frame_view.apply_frame_state(state), "frame presentation applies valid state")
	_assert(frame_view.content_renderer() == scatter and frame_view.table_view() == table, "frame exposes bound content ports")
	_assert(scatter.get_parent() == frame_view.content_root(), "frame owns renderer under stable content root")
	_assert(frame_view.guide_root().name == "GuideRoot" and frame_view.chrome_root().name == "ChromeRoot" and frame_view.handle_root().name == "HandleRoot", "frame exposes stable presentation roots")
	_assert(scatter.plot_size.is_equal_approx(Vector3(4.0, 3.0, 4.0) * 0.625), "preserve aspect fits content within frame bounds")
	var frame_lifecycle := frame_view.lifecycle_snapshot()
	var applied_transform: Transform3D = frame_view.transform
	var applied_bounds: Vector3 = frame_view.bounds_node().mesh.size
	var invalid_presentation_state = FrameState.new("", Transform3D.IDENTITY, Vector3.ZERO)
	_assert(not frame_view.apply_frame_state(invalid_presentation_state), "invalid state is rejected atomically")
	_assert(frame_view.transform.is_equal_approx(applied_transform) and frame_view.bounds_node().mesh.size.is_equal_approx(applied_bounds), "invalid state preserves last-good presentation")
	var status_state = FrameState.from_dictionary(state.to_dictionary())
	status_state.locked = true
	status_state.visible = false
	status_state.source_status = "stale"
	status_state.theme_ref = "theme-high-contrast"
	status_state.aspect_policy = "fit"
	_assert(frame_view.apply_frame_state(status_state), "status and fit-aspect state applies")
	_assert(not frame_view.visible and not frame_view.handle_root().visible, "visibility and lock project without deleting roots")
	_assert(frame_view.chrome_snapshot() == {"title": "Annual trials", "source_status": "stale", "theme_ref": "theme-high-contrast", "locked": true}, "chrome port exposes title, status, theme, and lock")
	_assert(scatter.plot_size.is_equal_approx(status_state.bounds), "fit aspect fills frame bounds")
	status_state.visible = true
	status_state.locked = false
	status_state.aspect_policy = "free"
	_assert(frame_view.apply_frame_state(status_state), "free-aspect state applies")
	_assert(scatter.plot_size.is_equal_approx(Vector3(4.0, 3.0, 4.0)), "free aspect preserves renderer-authored size")
	_assert(frame_view.apply_frame_state(state), "authored frame presentation restores")

	var manifest := _load_json("res://tests/m1/fixtures/replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest["messages"]:
		messages.append(_load_json("res://tests/m1/fixtures/" + filename))
	var replay = Replay.new()
	var session = Session.new()
	session.bind(replay, frame_view, table)
	replay.load_messages(messages)
	replay.step()
	replay.step()
	var render_node_id := scatter.render_node().get_instance_id()
	var render_resource_id := scatter.render_resource().get_instance_id()
	var guide_lifecycle := guides.lifecycle_snapshot()
	_assert(guides.title_text() == "Annual clinical trial enrollment", "figure title renders through chrome root")
	_assert(guides.get_node("AxisTitle0").text == "Year" and guides.get_node("AxisTitle1").text == "Sites" and guides.get_node("AxisTitle2").text == "Enrollment", "source axis titles render from guide contracts")
	_assert(frame_view.chrome_root().get_node("FigureTitle").get_parent() == frame_view.chrome_root(), "figure title is owned by frame chrome root")
	_assert(guides.get_parent() == frame_view.guide_root(), "guide renderer remains under frame guide root")
	_assert(guides.lifecycle_snapshot()["active_tick_labels"] == 11, "XYZ tick labels are materialized deterministically")
	_assert(guides.lifecycle_snapshot()["landmark_label_pool"] == 4, "orientation and reset landmarks are retained")
	_assert(guides.lifecycle_snapshot()["axis_surfaces"] == 1 and guides.lifecycle_snapshot()["grid_surfaces"] == 1, "retained axes and grid line surfaces are populated")
	_assert("2024" in guides.visible_tick_texts() and "250" in guides.visible_tick_texts(), "visible guide labels expose source-domain values")
	while replay.status != replay.Status.COMPLETE:
		replay.step()
	_assert(session.active_revision == 2, "compatible replay reaches revision two inside frame")
	_assert(scatter.render_node().get_instance_id() == render_node_id and scatter.render_resource().get_instance_id() == render_resource_id, "compatible revision preserves framed renderer resources")
	_assert(guides.lifecycle_snapshot() == guide_lifecycle, "compatible revision preserves guide nodes, meshes, and label pools")
	_assert(frame_view.transform.is_equal_approx(applied_transform), "plot revision does not mutate frame transform")
	_assert(Array(session.linked_selection.row_ids) == manifest["expected"]["preserved_row_ids"], "framed content preserves linked selection")
	var public_diagnostics = Diagnostics.new()
	public_diagnostics.bind(replay, session, frame_view, table)
	var diagnostic_snapshot: Dictionary = public_diagnostics.snapshot()
	_assert(diagnostic_snapshot["renderer"]["rendered_points"] == 4, "frame facade preserves public renderer diagnostics")
	_assert(diagnostic_snapshot["renderer"]["guides"]["active_tick_labels"] == 11, "public diagnostics expose retained guide lifecycle")
	var domain_controller = AxisDomainInteraction.new()
	_assert(domain_controller.bind(frame_view, session.active_figure), "axis-domain controller binds current Cartesian figure")
	var original_domains: Dictionary = domain_controller.domain_snapshot()
	_assert(domain_controller.begin("x", "min") and domain_controller.preview_delta(0.25), "axis-domain controller previews X minimum")
	var preview_domains: Dictionary = domain_controller.domain_snapshot()
	_assert(float(preview_domains["x"]["min"]) > float(original_domains["x"]["min"]), "X minimum preview narrows domain")
	_assert(scatter.rendered_point_count() <= 4, "domain preview reapplies scatter under narrowed scale")
	_assert(domain_controller.cancel(), "axis-domain controller cancels preview")
	_assert(domain_controller.domain_snapshot() == original_domains, "axis-domain cancel restores exact domains")
	_assert(domain_controller.begin("z", "max") and domain_controller.preview_delta(0.20) and domain_controller.commit(), "axis-domain controller commits Z maximum expansion")
	var committed_domains: Dictionary = domain_controller.domain_snapshot()
	_assert(float(committed_domains["z"]["max"]) > float(original_domains["z"]["max"]), "Z maximum commit expands domain")
	_assert(not domain_controller.begin("q", "min"), "axis-domain controller rejects unsupported channel")
	frame_lifecycle = frame_view.lifecycle_snapshot()
	for iteration: int in 100:
		_assert(frame_view.apply_frame_state(state), "repeated valid state applies: %d" % iteration)
	_assert(frame_view.lifecycle_snapshot() == frame_lifecycle, "repeated state projection preserves frame nodes and child counts")
	_assert(scatter.render_node().get_instance_id() == render_node_id and scatter.render_resource().get_instance_id() == render_resource_id, "repeated frame state preserves content resources")

	var controller = FrameInteraction.new()
	_assert(controller.bind(state, frame_view), "device-independent frame controller binds state and presentation")
	_assert(controller.accepts_intent("select") and not controller.accepts_intent("move"), "content mode owns inspection intents only")
	_assert(not controller.begin("move", "pointer-a"), "content mode rejects frame manipulation")
	_assert(controller.set_mode("frame"), "controller enters frame mode")
	controller.set_selected(true)
	_assert(frame_view.interaction_snapshot()["handles_visible"], "selected frame mode exposes visible handle ownership")
	var authored_state: Dictionary = state.to_dictionary()
	_assert(controller.begin("move", "pointer-a"), "selected unlocked frame begins move capture")
	_assert(frame_view.interaction_snapshot()["capturing"], "capture is visibly projected to frame")
	_assert(controller.preview_move(Vector3(1.0, 2.0, -1.0), "pointer-a"), "move preview applies from capture origin")
	_assert(state.transform.origin.is_equal_approx(authored.origin + Vector3(1.0, 2.0, -1.0)), "move preview changes only current frame transform")
	_assert(not controller.preview_move(Vector3.ZERO, "pointer-b"), "non-owner cannot preview capture")
	_assert(controller.cancel(), "active move capture cancels")
	_assert(state.to_dictionary() == authored_state and controller.history_snapshot()["size"] == 0, "cancel restores exact state without history")

	_assert(controller.begin("move", "pointer-a") and controller.preview_move(Vector3(1.0, 0.0, 0.0), "pointer-a") and controller.commit("pointer-a"), "move preview commits")
	var moved_state: Dictionary = state.to_dictionary()
	_assert(controller.history_snapshot()["size"] == 1 and controller.history_snapshot()["can_undo"], "committed move enters bounded history")
	_assert(controller.undo() and state.to_dictionary() == authored_state, "undo restores exact pre-move state")
	_assert(controller.redo() and state.to_dictionary() == moved_state, "redo restores exact committed move")
	_assert(controller.begin("rotate", "pointer-a") and controller.preview_rotate(Vector3(0.0, 0.25, 0.0), "pointer-a") and controller.commit("pointer-a"), "rotation preview commits")
	_assert(controller.begin("resize", "pointer-a") and controller.capture_snapshot()["operation"] == "resize", "resize capture begins without stealing another owner")
	_assert(not controller.preview_resize(Vector3.ZERO, "pointer-a"), "invalid resize preview is atomic")
	_assert(controller.preview_resize(Vector3(7.0, 5.0, 3.0), "pointer-a") and controller.commit("pointer-a"), "valid resize preview commits")
	_assert(state.bounds.is_equal_approx(Vector3(7.0, 5.0, 3.0)), "resize command changes frame bounds")
	_assert(controller.set_locked(true), "lock is a reversible command")
	_assert(not frame_view.interaction_snapshot()["handles_visible"] and not controller.begin("move", "pointer-a"), "locked frame hides handles and rejects manipulation")
	_assert(controller.set_locked(false), "unlock is a reversible command")

	var before_navigation_transform: Transform3D = state.transform
	var before_navigation_bounds: Vector3 = state.bounds
	_assert(controller.set_mode("navigate") and controller.accepts_intent("orbit") and not controller.accepts_intent("resize"), "navigate mode owns observer intents only")
	_assert(controller.update_navigation({"orientation": [0.1, 0.5, 0.0], "focus": [0.0, 0.0, 0.0]}), "navigate mode updates local view state")
	_assert(state.transform.is_equal_approx(before_navigation_transform) and state.bounds.is_equal_approx(before_navigation_bounds), "navigation never mutates frame transform or analytical bounds")
	_assert(controller.set_mode("frame"), "controller returns to frame mode")
	controller.set_selected(true)
	var before_capture_loss: Dictionary = state.to_dictionary()
	_assert(controller.begin("move", "pointer-a") and controller.preview_move(Vector3(5.0, 0.0, 0.0), "pointer-a"), "capture-loss fixture previews move")
	_assert(controller.set_mode("content") and state.to_dictionary() == before_capture_loss, "mode switch cancels capture and restores exact state")
	_assert(not frame_view.interaction_snapshot()["handles_visible"], "content mode hides frame handles")

	controller.set_mode("frame")
	controller.set_selected(true)
	_assert(controller.begin("move", "pointer-a") and controller.preview_move(Vector3(2.0, 0.0, 0.0), "pointer-a") and controller.commit("pointer-a"), "pre-reset move commits")
	_assert(controller.reset(), "reset returns to authored transform")
	_assert(state.transform.is_equal_approx(authored) and state.local_view_state.is_empty(), "reset restores authored transform and clears local navigation")
	_assert(controller.undo(), "reset is undoable")
	_assert(not state.transform.is_equal_approx(authored) and not state.local_view_state.is_empty(), "undo reset restores prior transform and navigation")
	_assert(controller.redo() and state.transform.is_equal_approx(authored), "redo reapplies exact reset")
	_assert(controller.undo(), "history can return before reset for branch test")
	_assert(controller.set_locked(true) and not controller.history_snapshot()["can_redo"], "new command after undo truncates redo branch")
	controller.history_limit = 2
	_assert(controller.set_locked(false) and controller.set_locked(true) and controller.set_locked(false), "bounded-history fixture commits lock transitions")
	_assert(controller.history_snapshot()["size"] == 2 and controller.history_snapshot()["cursor"] == 2, "history evicts oldest commands at configured limit")
	var trace_events := PackedStringArray()
	for entry: Dictionary in controller.command_trace:
		trace_events.append(entry["event"])
	for expected_event: String in ["mode", "selection", "begin", "preview", "cancel", "commit", "undo", "redo", "navigate", "reset"]:
		_assert(expected_event in trace_events, "command trace records deterministic event: " + expected_event)
	table.queue_free()
	frame_view.queue_free()

	if _failures == 0:
		print("Godot Charts M2 frame-state tests passed.")
		quit(0)
	else:
		push_error("M2 frame-state tests failed: %d assertion(s)." % _failures)
		quit(1)


func _codes(diagnostics: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for diagnostic: Dictionary in diagnostics:
		result.append(diagnostic["code"])
	return result


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
