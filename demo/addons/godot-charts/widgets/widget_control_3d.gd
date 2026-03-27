@tool
class_name WidgetControl3D
extends Area3D

## Shared state enum for all interactive controls.
enum State { NORMAL, HOVER, PRESSED, DISABLED, FOCUSED }

## Emitted when the pointer (mouse or XR ray) enters the control.
signal focus_entered
## Emitted when the pointer leaves the control.
signal focus_exited
## Forwarded XRToolsPointerEvent for XR consumers.
signal xr_pointer_event(event)

@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_state(State.NORMAL if value else State.DISABLED)

@export var widget_size: Vector2 = Vector2(0.36, 0.10):
	set(value):
		widget_size = Vector2(max(0.01, value.x), max(0.01, value.y))
		_queue_rebuild()

## Optional shared theme resource.  When null, built-in defaults are used.
@export var theme_data: WidgetThemeData3D:
	set(value):
		theme_data = value
		_queue_rebuild()

var _state: State = State.NORMAL
var _keyboard_focused: bool = false
var _rebuild_queued: bool = false
var _bg_mat: StandardMaterial3D
var _border_mat: StandardMaterial3D
var _border_inst: MeshInstance3D
var _shape: CollisionShape3D

const _BORDER_W: float = 0.006  # 6 mm frame around each control


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	input_ray_pickable = true

	_ensure_children()
	_queue_rebuild()

	if not Engine.is_editor_hint():
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		input_event.connect(_on_input_event)
		var fm := _get_focus_manager()
		if fm:
			fm.register(self)
		var tm := _get_theme_manager()
		if tm:
			tm.theme_changed.connect(_on_global_theme_changed)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		var fm := _get_focus_manager()
		if fm:
			fm.unregister(self)


func _process(_delta: float) -> void:
	if _rebuild_queued:
		_rebuild_queued = false
		_rebuild()


func _rebuild() -> void:
	_ensure_children()
	_apply_shape()
	_apply_colors()


func _queue_rebuild() -> void:
	_rebuild_queued = true


# ── child creation ────────────────────────────────────────────────────────────

func _ensure_children() -> void:
	if not is_instance_valid(_shape):
		_shape = CollisionShape3D.new()
		_shape.name = "_shape"
		add_child(_shape)
	if not is_instance_valid(_bg_mat):
		_bg_mat = StandardMaterial3D.new()
		_bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not is_instance_valid(_border_mat):
		_border_mat = StandardMaterial3D.new()
		_border_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if not is_instance_valid(_border_inst):
		_border_inst = MeshInstance3D.new()
		_border_inst.name = "_border"
		_border_inst.material_override = _border_mat
		add_child(_border_inst)


func _apply_shape() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(widget_size.x, widget_size.y, 0.002)
	_shape.shape = box

	var bw := _BORDER_W
	var border_q := QuadMesh.new()
	border_q.size = Vector2(widget_size.x + bw * 2.0, widget_size.y + bw * 2.0)
	_border_inst.mesh = border_q
	_border_inst.position = Vector3(0.0, 0.0, -0.0005)


# ── color helpers ─────────────────────────────────────────────────────────────

## Returns the explicit theme_data override if set, otherwise the global
## WidgetThemeManager active theme, otherwise null (hardcoded defaults apply).
func _get_effective_theme() -> WidgetThemeData3D:
	if theme_data != null:
		return theme_data
	var tm := _get_theme_manager()
	if tm:
		return tm.get_active_theme()
	return null


func _get_bg_color() -> Color:
	var t := _get_effective_theme()
	match _state:
		State.HOVER:    return t.bg_hover    if t else Color(0.28, 0.28, 0.32)
		State.PRESSED:  return t.bg_pressed  if t else Color(0.12, 0.45, 0.82)
		State.DISABLED: return t.bg_disabled if t else Color(0.14, 0.14, 0.15)
		_:              return t.bg_normal   if t else Color(0.18, 0.18, 0.20)

func _get_text_color() -> Color:
	var t := _get_effective_theme()
	if _state == State.DISABLED:
		return t.text_disabled if t else Color(0.45, 0.45, 0.45)
	return t.text_normal if t else Color(0.95, 0.95, 0.95)

func _get_border_color() -> Color:
	var t := _get_effective_theme()
	if _keyboard_focused:
		return t.border_focused if t else Color(0.30, 0.65, 1.0)
	return t.border_normal if t else Color(0.35, 0.35, 0.40)

func _apply_colors() -> void:
	_bg_mat.albedo_color = _get_bg_color()
	if is_instance_valid(_border_mat):
		_border_mat.albedo_color = _get_border_color()


# ── state machine ─────────────────────────────────────────────────────────────

func _update_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	_apply_colors()


# ── keyboard focus (managed by WidgetFocusManager) ────────────────────────────

func _on_focus_gained() -> void:
	_keyboard_focused = true
	_apply_colors()


func _on_focus_lost() -> void:
	_keyboard_focused = false
	_apply_colors()


func _unhandled_key_input(event: InputEvent) -> void:
	if not _keyboard_focused or not enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var fm := _get_focus_manager()
		if not fm:
			return
		if event.keycode == KEY_TAB:
			if event.shift_pressed:
				fm.focus_prev(self)
			else:
				fm.focus_next(self)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_clicked()
			get_viewport().set_input_as_handled()


# ── desktop interaction ───────────────────────────────────────────────────────

func _on_mouse_entered() -> void:
	if not enabled:
		return
	_update_state(State.HOVER)
	emit_signal("focus_entered")


func _on_mouse_exited() -> void:
	if not enabled:
		return
	_update_state(State.NORMAL)
	emit_signal("focus_exited")


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_update_state(State.PRESSED if mb.pressed else State.HOVER)
			if not mb.pressed:
				var fm := _get_focus_manager()
				if fm:
					fm.request_focus(self, fm.InputMode.DESKTOP)
				_on_clicked()


# ── XR pointer (godot-xr-tools) ──────────────────────────────────────────────

## Called by XRToolsPointerEvent.report() when this node is the pointer target.
## event_type values: 0=ENTERED 1=EXITED 2=PRESSED 3=RELEASED 4=MOVED
func pointer_event(event: Object) -> void:
	xr_pointer_event.emit(event)
	if not enabled:
		return
	var t: int = event.get("event_type") if event else -1
	match t:
		0:  # ENTERED
			_update_state(State.HOVER)
			emit_signal("focus_entered")
		1:  # EXITED
			_update_state(State.NORMAL)
			emit_signal("focus_exited")
		2:  # PRESSED
			_update_state(State.PRESSED)
			var fm := _get_focus_manager()
			if fm:
				fm.request_focus(self, fm.InputMode.XR)
			_on_clicked()
		3:  # RELEASED
			_update_state(State.HOVER)


# ── override point ────────────────────────────────────────────────────────────

## Subclasses override this to react to a confirmed click/press.
func _on_clicked() -> void:
	pass


## Return preferred size for layout containers.
func get_widget_size() -> Vector2:
	return widget_size


# ── helpers ───────────────────────────────────────────────────────────────────

func _get_focus_manager() -> Node:
	return get_node_or_null("/root/WidgetFocusManager")


func _get_theme_manager() -> Node:
	return get_node_or_null("/root/WidgetThemeManager")


## Called when the global theme changes.  Controls with an explicit theme_data
## override are unaffected; all others rebuild to pick up the new tokens.
func _on_global_theme_changed(_theme: WidgetThemeData3D) -> void:
	if theme_data == null:
		_queue_rebuild()
