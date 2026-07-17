extends SceneTree

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
const ScatterRenderer = preload("res://addons/godot-charts/renderers/scatter_renderer_3d.gd")
const TableView = preload("res://addons/godot-charts/tables/bounded_table_view.gd")
const Selection = preload("res://addons/godot-charts/interactions/linked_selection.gd")
const Session = preload("res://addons/godot-charts/session/plot_session.gd")
const Diagnostics = preload("res://addons/godot-charts/diagnostics/plot_diagnostics.gd")
const FIXTURE_ROOT := "res://tests/m1/fixtures/"

var _failures: int = 0


func _initialize() -> void:
	var manifest := _load_json(FIXTURE_ROOT + "replay-manifest.json")
	var messages: Array[Dictionary] = []
	for filename: String in manifest["messages"]:
		messages.append(_load_json(FIXTURE_ROOT + filename))

	var replay = Replay.new()
	replay.load_messages(messages)
	_assert(replay.status == replay.Status.READY, "replay starts ready")
	_assert(replay.step(), "replay can step")
	_assert(replay.status == replay.Status.PAUSED, "step pauses before the end")
	replay.run_to_end()
	_assert(replay.status == replay.Status.COMPLETE, "replay completes")
	_assert(replay.applied_messages == manifest["expected"]["applied_messages"], "applied message count")
	_assert(replay.duplicate_messages == manifest["expected"]["duplicate_messages"], "duplicate is idempotent")
	_assert(replay.active_plot_revision == manifest["expected"]["active_plot_revision"], "replacement revision applied")
	_assert(Array(replay.selection_row_ids) == manifest["expected"]["preserved_row_ids"], "compatible selection preserved")
	_assert(replay.diagnostics.is_empty(), "valid replay has no errors")
	_assert(replay.active_figure != null, "plot replacement installs a retained figure")
	_assert(replay.active_figure.id == "figure-annual-trials", "figure identity is retained")
	_assert(replay.active_figure.table("dataset-annual-trials").value("trial-2023", "enrolled") == null, "missing table values remain missing")
	_assert(is_equal_approx(replay.active_figure.view("view-main").scales["x"].map(2023.0), 0.5), "linear scale maps deterministically")
	_assert(is_equal_approx(replay.active_figure.view("view-main").scales["x"].invert(0.5), 2023.0), "linear scale inversion is deterministic")
	_assert(replay.active_figure.view("view-main").scales["color"].map("II") == "#f59e0b", "categorical scale maps deterministically")
	_assert(replay.active_figure.view("view-main").scales["color"].map("unknown") == null, "unknown category remains missing")
	_assert(replay.active_figure.view("view-main").guides.size() == 4, "axes and legend remain retained guides")
	_assert(replay.last_figure_diff != null, "compatible replacement produces a diff")
	_assert(Array(replay.last_figure_diff.changed_tables) == ["dataset-annual-trials"], "replacement changes only its table")
	_assert(replay.last_figure_diff.changed_layers.is_empty(), "stable layer is not rebuilt")
	_assert(replay.last_figure_diff.changed_scales.is_empty(), "stable scales are not rebuilt")
	_assert(replay.last_figure_diff.changed_guides.is_empty(), "stable guides are not rebuilt")
	_assert(replay.last_figure_diff.added_row_ids.is_empty() and replay.last_figure_diff.removed_row_ids.is_empty(), "stable row identities survive replacement")

	var revision_one_replay = Replay.new()
	revision_one_replay.load_messages(messages.slice(0, 2))
	revision_one_replay.run_to_end()
	var renderer = ScatterRenderer.new()
	root.add_child(renderer)
	_assert(renderer.apply_figure(revision_one_replay.active_figure), "scatter renderer accepts retained figure")
	_assert(renderer.rendered_point_count() == 4, "missing positional row is not rendered")
	_assert(renderer.primitive_id_for_row("trial-2023").is_empty(), "missing positional row has no pick primitive")
	var stable_primitive := renderer.primitive_id_for_row("trial-2022")
	_assert(not stable_primitive.is_empty(), "rendered row has a stable primitive identity")
	var picked := renderer.resolve_primitive(stable_primitive)
	_assert(picked["row_id"] == "trial-2022" and picked["values"]["phase"] == "I", "pick resolves row identity and inspection values")
	var render_node_id := renderer.render_node().get_instance_id()
	var render_resource_id := renderer.render_resource().get_instance_id()
	var last_primitive := renderer.primitive_id_for_row("trial-2025")
	var old_position: Vector3 = renderer.resolve_primitive(last_primitive)["world_position"]
	_assert(renderer.apply_figure(replay.active_figure, replay.last_figure_diff), "compatible diff updates scatter renderer")
	_assert(renderer.render_node().get_instance_id() == render_node_id, "compatible update preserves render node")
	_assert(renderer.render_resource().get_instance_id() == render_resource_id, "compatible update preserves multimesh resource")
	_assert(renderer.primitive_id_for_row("trial-2022") == stable_primitive, "compatible update preserves primitive identity")
	_assert(renderer.resolve_primitive(stable_primitive)["dataset_revision"] == 2, "pick metadata advances dataset revision")
	var new_position: Vector3 = renderer.resolve_primitive(last_primitive)["world_position"]
	_assert(not old_position.is_equal_approx(new_position), "changed source value updates point transform")
	var render_benchmark_start := Time.get_ticks_usec()
	for iteration: int in 250:
		_assert(renderer.apply_figure(replay.active_figure, replay.last_figure_diff), "repeated compatible update applies: %d" % iteration)
	var render_benchmark_ms := float(Time.get_ticks_usec() - render_benchmark_start) / 1000.0
	_assert(render_benchmark_ms < 5000.0, "250 compatible scatter updates stay within the 5 second headless budget")
	print("M1 benchmark scatter_updates=250 elapsed_ms=%.3f per_update_ms=%.3f points=%d" % [render_benchmark_ms, render_benchmark_ms / 250.0, renderer.rendered_point_count()])
	_assert(renderer.get_child_count() == 1, "repeated updates do not grow the scene tree")
	_assert(renderer.render_node().get_instance_id() == render_node_id, "repeated updates preserve render node")
	_assert(renderer.render_resource().get_instance_id() == render_resource_id, "repeated updates preserve render resource")

	var table_model: RefCounted = replay.active_figure.table("dataset-annual-trials")
	var table_before_selection := JSON.stringify(table_model.to_dictionary())
	var table_view = TableView.new()
	table_view.max_visible_rows = 3
	root.add_child(table_view)
	table_view.display_window(table_model, 1, 100)
	_assert(table_view.displayed_row_count() == 3, "table materializes no more than its bounded window")
	_assert(Array(table_view.visible_row_ids()) == ["trial-2022", "trial-2023", "trial-2024"], "table window preserves stable row order")
	_assert(table_view.inspect_row("trial-2023")["enrolled"] == null, "table inspection preserves missing values")

	var linked_selection = Selection.new()
	linked_selection.bind_table(table_view)
	linked_selection.bind_scatter_renderer(renderer)
	table_view.set_selected_rows(PackedStringArray(["trial-2022"]), true, "test")
	_assert(Array(linked_selection.row_ids) == ["trial-2022"], "table selection updates normalized selection state")
	_assert(renderer.is_row_selected("trial-2022"), "table selection highlights matching chart row")
	linked_selection.select_from_chart("trial-2024")
	_assert(Array(table_view.selected_row_ids()) == ["trial-2024"], "chart selection focuses matching visible table row")
	_assert(renderer.is_row_selected("trial-2024") and not renderer.is_row_selected("trial-2022"), "chart selection replaces renderer selection")
	linked_selection.select_from_chart("trial-2022", true)
	_assert(Array(linked_selection.row_ids) == ["trial-2024", "trial-2022"], "additive chart selection preserves normalized ordering")
	_assert(JSON.stringify(table_model.to_dictionary()) == table_before_selection, "linked selection never mutates source table data")
	var table_benchmark_start := Time.get_ticks_usec()
	for iteration: int in 250:
		table_view.display_window(table_model, 1, 3)
	var table_benchmark_ms := float(Time.get_ticks_usec() - table_benchmark_start) / 1000.0
	_assert(table_benchmark_ms < 5000.0, "250 bounded table refreshes stay within the 5 second headless budget")
	print("M1 benchmark table_refreshes=250 elapsed_ms=%.3f per_refresh_ms=%.3f visible_rows=%d" % [table_benchmark_ms, table_benchmark_ms / 250.0, table_view.displayed_row_count()])
	_assert(table_view.get_child_count() == 1, "repeated table windows preserve one Tree control")
	_assert(table_view.displayed_row_count() == 3, "repeated table windows remain bounded")
	_assert(Array(table_view.selected_row_ids()) == ["trial-2022", "trial-2024"], "eligible visible selections survive table refresh")
	table_view.queue_free()
	renderer.queue_free()

	var coordinated_messages: Array = messages.duplicate(true)
	coordinated_messages.append(_load_json(FIXTURE_ROOT + "06-plot-r3-identity-reset.json"))
	var coordinated_replay = Replay.new()
	coordinated_replay.load_messages(coordinated_messages)
	var coordinated_renderer = ScatterRenderer.new()
	var coordinated_table = TableView.new()
	coordinated_table.max_visible_rows = 3
	root.add_child(coordinated_renderer)
	root.add_child(coordinated_table)
	var plot_session = Session.new()
	plot_session.bind(coordinated_replay, coordinated_renderer, coordinated_table)
	coordinated_replay.step()
	coordinated_replay.step()
	_assert(plot_session.active_revision == 1, "session installs initial plot revision")
	coordinated_renderer.transform = Transform3D(Basis.from_euler(Vector3(0.0, 0.4, 0.0)), Vector3(2.0, 1.0, -3.0))
	var preserved_frame_transform: Transform3D = coordinated_renderer.transform
	coordinated_table.display_window(plot_session.active_figure.table("dataset-annual-trials"), 1, 3)
	var coordinated_node_id := coordinated_renderer.render_node().get_instance_id()
	var coordinated_resource_id := coordinated_renderer.render_resource().get_instance_id()
	var coordinated_primitive := coordinated_renderer.primitive_id_for_row("trial-2022")
	while coordinated_replay.cursor < messages.size():
		coordinated_replay.step()
	_assert(plot_session.active_revision == 2, "session applies compatible replacement")
	_assert(coordinated_table.window_offset == 1 and coordinated_table.window_limit == 3, "compatible replacement preserves table window")
	_assert(Array(plot_session.linked_selection.row_ids) == ["trial-2022", "trial-2024"], "compatible replacement preserves linked selection")
	_assert(Array(coordinated_table.selected_row_ids()) == ["trial-2022", "trial-2024"], "compatible replacement preserves visible table selection")
	_assert(coordinated_renderer.primitive_id_for_row("trial-2022") == coordinated_primitive, "compatible replacement preserves picking identity")
	_assert(coordinated_renderer.render_node().get_instance_id() == coordinated_node_id, "session preserves renderer node")
	_assert(coordinated_renderer.render_resource().get_instance_id() == coordinated_resource_id, "session preserves renderer resource")
	_assert(coordinated_renderer.transform.is_equal_approx(preserved_frame_transform), "compatible replacement preserves frame transform")
	coordinated_replay.step()
	_assert(plot_session.active_revision == 3, "session applies declared identity replacement")
	_assert(plot_session.linked_selection.row_ids.is_empty(), "identity replacement resets only invalid selection")
	_assert(coordinated_table.window_offset == 1 and coordinated_table.window_limit == 3, "identity replacement preserves table window")
	_assert(coordinated_renderer.resolve_primitive(coordinated_primitive).is_empty(), "removed row primitive is no longer pickable")
	_assert(coordinated_renderer.render_node().get_instance_id() == coordinated_node_id, "identity replacement still preserves renderer node")
	_assert(coordinated_renderer.render_resource().get_instance_id() == coordinated_resource_id, "identity replacement still preserves renderer resource")
	_assert(coordinated_renderer.transform.is_equal_approx(preserved_frame_transform), "identity replacement preserves frame transform")
	_assert(plot_session.diagnostics.is_empty(), "valid coordinated replacements add no session errors")
	var public_diagnostics = Diagnostics.new()
	public_diagnostics.bind(coordinated_replay, plot_session, coordinated_renderer, coordinated_table)
	var diagnostic_snapshot: Dictionary = public_diagnostics.snapshot()
	_assert(diagnostic_snapshot["schema"] == "godot-charts/plot-message/1.0", "diagnostics expose active schema")
	_assert(diagnostic_snapshot["message_id"] == "message-plot-r3", "diagnostics expose active message identity")
	_assert(diagnostic_snapshot["revision"] == 3, "diagnostics expose coordinated revision")
	_assert(diagnostic_snapshot["producer"]["library"] == "matplotlib", "diagnostics expose source library")
	_assert(diagnostic_snapshot["producer"]["adapter"] == "godot-charts-matplotlib", "diagnostics expose adapter")
	_assert(diagnostic_snapshot["provenance"]["dataset_revision"] == 3, "diagnostics expose provenance revision")
	_assert(diagnostic_snapshot["protocol_limits"]["max_rows"] == 10000, "diagnostics expose negotiated limits")
	_assert(diagnostic_snapshot["replay"]["status"] == "complete", "diagnostics expose replay status")
	_assert(diagnostic_snapshot["replay"]["duplicate_messages"] == 1, "diagnostics expose duplicate delivery")
	_assert(diagnostic_snapshot["renderer"]["rendered_points"] == 4, "diagnostics expose missing-aware render count")
	_assert(diagnostic_snapshot["renderer"]["renderer_child_count"] == 1, "diagnostics expose renderer lifecycle")
	_assert(diagnostic_snapshot["table"]["offset"] == 1 and diagnostic_snapshot["table"]["limit"] == 3, "diagnostics expose bounded table window")
	_assert(diagnostic_snapshot["selection"]["row_ids"].is_empty(), "diagnostics expose cleared linked selection")
	_assert(diagnostic_snapshot["source_diagnostics"][0]["code"] == "missing-values-skipped", "diagnostics expose source conversion notices")
	_assert("identity-reset" in _codes_from_diagnostics(diagnostic_snapshot["diagnostics"]), "diagnostics expose identity reset")
	_assert(diagnostic_snapshot["approximations"].is_empty(), "diagnostics distinguish absent approximations")
	_assert(diagnostic_snapshot["rejected_fields"].is_empty(), "valid session has no rejected fields")
	coordinated_replay.diagnostics.append({"severity": "warning", "code": "source-feature-approximated", "message": "Fixture approximation", "path": "/payload/figure/views/0", "fidelity": "approximated"})
	coordinated_replay.diagnostics.append({"severity": "error", "code": "rejected-field", "message": "Fixture rejection", "path": "/payload/unsupported"})
	var classified_snapshot: Dictionary = public_diagnostics.snapshot()
	_assert(classified_snapshot["approximations"][0]["code"] == "source-feature-approximated", "diagnostics classify approximations")
	_assert(classified_snapshot["rejected_fields"][0]["path"] == "/payload/unsupported", "diagnostics classify rejected fields by path")
	_assert(public_diagnostics.to_json() == public_diagnostics.to_json(), "public diagnostics serialize deterministically")
	coordinated_table.queue_free()
	coordinated_renderer.queue_free()

	var first_result := _snapshot(replay)
	var first_figure_json := JSON.stringify(replay.active_figure.to_dictionary())
	replay.restart()
	replay.run_to_end()
	_assert(_snapshot(replay) == first_result, "restart is deterministic")
	_assert(JSON.stringify(replay.active_figure.to_dictionary()) == first_figure_json, "normalized figure serialization is deterministic")

	var invalid := messages[1].duplicate(true)
	invalid["message_id"] = "message-invalid-columns"
	invalid["sequence"] = 5
	invalid["payload"]["figure"]["data"][0]["columns"]["year"].pop_back()
	var invalid_replay = Replay.new()
	invalid_replay.load_messages([invalid])
	invalid_replay.run_to_end()
	_assert(invalid_replay.applied_messages == 0, "invalid message is atomic")
	_assert(invalid_replay.diagnostics[0]["code"] == "column-length", "invalid message is diagnosed")

	var invalid_mapping: Dictionary = messages[1].duplicate(true)
	invalid_mapping["message_id"] = "message-invalid-mapping"
	invalid_mapping["sequence"] = 0
	invalid_mapping["payload"]["figure"]["views"][0]["layers"][0]["mappings"]["x"] = "absent-column"
	var mapping_replay = Replay.new()
	mapping_replay.load_messages([invalid_mapping])
	mapping_replay.run_to_end()
	_assert(mapping_replay.active_figure == null, "invalid mapping does not install a figure")
	_assert("missing-column" in _diagnostic_codes(mapping_replay), "invalid mapping reports its semantic error")

	var identity_reset := _load_json(FIXTURE_ROOT + "06-plot-r3-identity-reset.json")
	var reset_replay = Replay.new()
	reset_replay.load_messages(messages + [identity_reset])
	reset_replay.run_to_end()
	_assert(reset_replay.active_plot_revision == 3, "declared identity-breaking replacement applies")
	_assert(reset_replay.selection_row_ids.is_empty(), "declared identity reset clears incompatible rows")
	_assert("identity-reset" in _diagnostic_codes(reset_replay), "declared identity reset is diagnosed")
	_assert(reset_replay.last_figure_diff.added_row_ids.size() == 5, "identity replacement reports added rows")
	_assert(reset_replay.last_figure_diff.removed_row_ids.size() == 5, "identity replacement reports removed rows")

	var undeclared_reset := _load_json(FIXTURE_ROOT + "negative/identity-break-undeclared.json")
	var undeclared_replay = Replay.new()
	undeclared_replay.load_messages(messages + [undeclared_reset])
	undeclared_replay.run_to_end()
	_assert(undeclared_replay.active_plot_revision == 2, "undeclared identity break preserves last-good plot")
	_assert(Array(undeclared_replay.selection_row_ids) == manifest["expected"]["preserved_row_ids"], "undeclared identity break preserves selection")
	_assert("identity-break-undeclared" in _diagnostic_codes(undeclared_replay), "undeclared identity break is rejected")

	var gap := _load_json(FIXTURE_ROOT + "negative/sequence-gap.json")
	var gap_replay = Replay.new()
	gap_replay.load_messages(messages + [gap])
	gap_replay.run_to_end()
	_assert(gap_replay.active_plot_revision == 2, "sequence gap preserves last-good plot")
	_assert("sequence-gap" in _diagnostic_codes(gap_replay), "sequence gap requests resynchronization")

	var stale := _load_json(FIXTURE_ROOT + "negative/stale-revision.json")
	var stale_replay = Replay.new()
	stale_replay.load_messages(messages + [stale])
	stale_replay.run_to_end()
	_assert(stale_replay.active_plot_revision == 2, "stale revision preserves last-good plot")
	_assert("stale-revision" in _diagnostic_codes(stale_replay), "stale revision is diagnosed")

	var unbounded_request: Dictionary = messages[2].duplicate(true)
	unbounded_request["message_id"] = "message-table-request-unbounded"
	unbounded_request["sequence"] = 0
	unbounded_request["payload"]["limit"] = 1001
	var limit_replay = Replay.new()
	limit_replay.load_messages([unbounded_request])
	limit_replay.run_to_end()
	_assert(limit_replay.applied_messages == 0, "unbounded table request is atomic")
	_assert("row-limit" in _diagnostic_codes(limit_replay), "unbounded table request is diagnosed")

	var oversized: Dictionary = identity_reset.duplicate(true)
	oversized["message_id"] = "message-plot-oversized"
	oversized["payload"]["figure"]["title"] = "x".repeat(1_048_576)
	var oversized_replay = Replay.new()
	oversized_replay.load_messages(messages + [oversized])
	oversized_replay.run_to_end()
	_assert(oversized_replay.active_plot_revision == 2, "oversized replacement preserves last-good plot")
	_assert("message-too-large" in _diagnostic_codes(oversized_replay), "oversized replacement is rejected before mutation")

	if _failures == 0:
		print("M1 Godot contract/replay tests passed.")
		quit(0)
	else:
		push_error("M1 Godot contract/replay tests failed: %d assertion(s)." % _failures)
		quit(1)


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "fixture opens: " + path)
	var value: Variant = JSON.parse_string(file.get_as_text())
	_assert(value is Dictionary, "fixture parses: " + path)
	return value


func _snapshot(replay: RefCounted) -> Dictionary:
	return {
		"applied": replay.applied_messages,
		"duplicates": replay.duplicate_messages,
		"revision": replay.active_plot_revision,
		"selection": Array(replay.selection_row_ids),
		"diagnostics": replay.diagnostics.duplicate(true),
	}


func _diagnostic_codes(replay: RefCounted) -> PackedStringArray:
	var codes := PackedStringArray()
	for diagnostic: Dictionary in replay.diagnostics:
		codes.append(diagnostic["code"])
	return codes


func _codes_from_diagnostics(diagnostics: Array) -> PackedStringArray:
	var codes := PackedStringArray()
	for diagnostic: Dictionary in diagnostics:
		codes.append(diagnostic["code"])
	return codes


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
