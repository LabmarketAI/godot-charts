## First-person player controller for the desktop data-room demo.
##
## Attach to a [CharacterBody3D] that has a [Camera3D] child named "Camera3D"
## and a [CollisionShape3D] (CapsuleShape3D radius=0.3, height=1.8).
##
## [b]Controls[/b]
## [code]W/S/↑/↓[/code]  — walk forward / back
## [code]A/D[/code]       — strafe left / right
## [b]Mouse[/b]           — look
## [code]Escape[/code]    — toggle mouse capture
extends CharacterBody3D

const SPEED             := 5.0    ## Walking speed (m/s).
const MOUSE_SENSITIVITY := 0.003  ## Mouse-look radians per pixel.

@onready var _camera: Camera3D = $Camera3D

var _mouse_captured: bool = false


func _ready() -> void:
	_set_mouse_captured(true)


func _set_mouse_captured(captured: bool) -> void:
	_mouse_captured = captured
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		var me := event as InputEventMouseMotion
		rotate_y(-me.relative.x * MOUSE_SENSITIVITY)
		_camera.rotate_x(-me.relative.y * MOUSE_SENSITIVITY)
		_camera.rotation.x = clampf(_camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))
	if event is InputEventKey and (event as InputEventKey).pressed:
		if (event as InputEventKey).keycode == KEY_ESCAPE:
			_set_mouse_captured(not _mouse_captured)


func _physics_process(delta: float) -> void:
	# Gravity.
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * delta

	# WASD movement — direct key polling avoids needing action-map entries.
	var fw := int(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var bk := int(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	var lt := int(Input.is_key_pressed(KEY_A))
	var rt := int(Input.is_key_pressed(KEY_D))

	# input_dir.x = strafe (positive = right), input_dir.y = forward/back
	# (positive = backward because +Z in local space is the back direction).
	var input_dir := Vector2(rt - lt, bk - fw)
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


## Teleport the player to [param pos] and face [param look_at_pos].
## Used by [method main.gd/_fly_to] when the user presses [1]–[7].
func teleport_to(pos: Vector3, look_at_pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_camera.rotation.x = 0.0
	# Flatten the look target to the player's Y so pitch stays level.
	var flat_target := Vector3(look_at_pos.x, global_position.y, look_at_pos.z)
	if global_position.distance_to(flat_target) > 0.001:
		look_at(flat_target, Vector3.UP)
