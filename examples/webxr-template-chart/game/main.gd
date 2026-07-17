@tool
class_name GameStaging
extends PersistentStaging


## Game Staging Script
##
## This script registers the staging instance with the [GameState] singleton
## and handles pausing/resuming.


const WEBXR_EXIT_ACTIONS := [&"menu_button", &"primary_click"]

var _webxr_exit_button_held := false


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Connect events
	scene_loaded.connect(_on_scene_loaded)
	xr_started.connect(_on_xr_started)
	xr_ended.connect(_on_xr_ended)


# This method is called when a scene is loaded
func _on_scene_loaded(_scene : XRToolsSceneBase, _user_data : Variant) -> void:
	# Clear the continue prompt
	prompt_for_continue = false


# This method is called when the player starts the VR experience
func _on_xr_started() -> void:
	# Resume the game
	get_tree().paused = false


# This method is called when the player ends the VR experience
func _on_xr_ended() -> void:
	# Pause the game
	get_tree().paused = true


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not XRToolsStartXR.is_xr_active():
		_webxr_exit_button_held = false
		return

	var exit_pressed := _is_webxr_exit_pressed()
	if exit_pressed and not _webxr_exit_button_held:
		_webxr_exit_button_held = true
		var start_xr := get_node_or_null("StartXR")
		if start_xr != null and start_xr.has_method("end_xr"):
			start_xr.end_xr()
	elif not exit_pressed:
		_webxr_exit_button_held = false


func _is_webxr_exit_pressed() -> bool:
	for node: Node in find_children("*", "XRController3D", true, false):
		var controller := node as XRController3D
		if controller == null or not controller.get_is_active():
			continue
		for action: StringName in WEBXR_EXIT_ACTIONS:
			if controller.is_button_pressed(action):
				return true
	return false
