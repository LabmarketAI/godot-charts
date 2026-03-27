extends Node

## Emitted when keyboard or XR focus moves to a new widget (or clears to null).
signal focus_changed(old_widget: Node, new_widget: Node)

## How the focused widget received focus.
enum InputMode { NONE, KEYBOARD, DESKTOP, XR }

var _focused: Object = null
var _input_mode: InputMode = InputMode.NONE
var _registered: Array = []


## Register a WidgetControl3D so Tab navigation can reach it.
func register(widget) -> void:
	if not _registered.has(widget):
		_registered.append(widget)


## Unregister a widget (called from _exit_tree).
func unregister(widget) -> void:
	_registered.erase(widget)
	if _focused == widget:
		_focused = null
		_input_mode = InputMode.NONE


## Move keyboard/XR focus to widget.  Pass null to clear focus.
func request_focus(widget, mode: InputMode = InputMode.DESKTOP) -> void:
	if _focused == widget:
		return
	var old = _focused
	if is_instance_valid(old) and old.has_method("_on_focus_lost"):
		old._on_focus_lost()
	_focused = widget
	_input_mode = mode
	if is_instance_valid(widget) and widget.has_method("_on_focus_gained"):
		widget._on_focus_gained()
	focus_changed.emit(old, widget)


## Release focus if widget currently holds it.
func release_focus(widget) -> void:
	if _focused != widget:
		return
	request_focus(null, InputMode.NONE)


## Move focus to the next registered widget (Tab).
func focus_next(from) -> void:
	_cycle(from, 1)


## Move focus to the previous registered widget (Shift+Tab).
func focus_prev(from) -> void:
	_cycle(from, -1)


## Return the currently focused widget, or null.
func get_focused() -> Object:
	return _focused


## Return the InputMode used to acquire current focus.
func get_input_mode() -> InputMode:
	return _input_mode


func _cycle(from, dir: int) -> void:
	var active: Array = _registered.filter(
		func(w): return is_instance_valid(w) and w.enabled and w.is_visible_in_tree()
	)
	if active.is_empty():
		return
	var idx: int = active.find(from)
	if idx == -1:
		idx = 0
	else:
		idx = (idx + dir + active.size()) % active.size()
	request_focus(active[idx], InputMode.KEYBOARD)
