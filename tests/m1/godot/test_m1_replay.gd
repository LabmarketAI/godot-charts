extends SceneTree

const Replay = preload("res://addons/godot-charts/protocol/m1_recorded_replay.gd")
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

	var first_result := _snapshot(replay)
	replay.restart()
	replay.run_to_end()
	_assert(_snapshot(replay) == first_result, "restart is deterministic")

	var invalid := messages[1].duplicate(true)
	invalid["message_id"] = "message-invalid-columns"
	invalid["sequence"] = 5
	invalid["payload"]["figure"]["data"][0]["columns"]["year"].pop_back()
	var invalid_replay = Replay.new()
	invalid_replay.load_messages([invalid])
	invalid_replay.run_to_end()
	_assert(invalid_replay.applied_messages == 0, "invalid message is atomic")
	_assert(invalid_replay.diagnostics[0]["code"] == "column-length", "invalid message is diagnosed")

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


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Assertion failed: " + message)
