extends Node

## Emitted when the active theme changes.  All controls without an explicit
## theme_data override will rebuild in response to this signal.
signal theme_changed(theme: WidgetThemeData3D)

## Names of available built-in presets.
const PRESET_NEUTRAL := "neutral"
const PRESET_HIGH_CONTRAST := "high_contrast"

var _active: WidgetThemeData3D = null


func _ready() -> void:
	_active = _build_neutral()


# ── public API ────────────────────────────────────────────────────────────────

## Return the currently active theme.  Never null after _ready().
func get_active_theme() -> WidgetThemeData3D:
	return _active


## Switch to a named built-in preset ("neutral" or "high_contrast").
func set_preset(name: String) -> void:
	match name:
		PRESET_NEUTRAL:
			_apply(_build_neutral())
		PRESET_HIGH_CONTRAST:
			_apply(_build_high_contrast())
		_:
			push_warning("WidgetThemeManager: unknown preset '%s'." % name)


## Switch to an arbitrary WidgetThemeData3D resource.
## Has no effect and logs a warning if theme is null.
func set_theme_resource(theme: WidgetThemeData3D) -> void:
	if theme == null:
		push_warning("WidgetThemeManager: set_theme_resource called with null; keeping current theme.")
		return
	_apply(theme)


# ── internal ──────────────────────────────────────────────────────────────────

func _apply(theme: WidgetThemeData3D) -> void:
	_active = theme
	theme_changed.emit(_active)


static func _build_neutral() -> WidgetThemeData3D:
	var t := WidgetThemeData3D.new()
	t.bg_normal      = Color(0.18, 0.18, 0.20)
	t.bg_hover       = Color(0.28, 0.28, 0.32)
	t.bg_pressed     = Color(0.12, 0.45, 0.82)
	t.bg_disabled    = Color(0.14, 0.14, 0.15)
	t.bg_checked     = Color(0.12, 0.45, 0.82)
	t.border_normal  = Color(0.35, 0.35, 0.40)
	t.border_focused = Color(0.30, 0.65, 1.00)
	t.text_normal    = Color(0.95, 0.95, 0.95)
	t.text_disabled  = Color(0.45, 0.45, 0.45)
	t.accent         = Color(0.12, 0.45, 0.82)
	t.slider_track   = Color(0.25, 0.25, 0.28)
	t.slider_thumb   = Color(0.12, 0.45, 0.82)
	t.text_size      = 18
	t.border_width   = 0.004
	return t


static func _build_high_contrast() -> WidgetThemeData3D:
	var t := WidgetThemeData3D.new()
	t.bg_normal      = Color(0.00, 0.00, 0.00)
	t.bg_hover       = Color(0.20, 0.20, 0.20)
	t.bg_pressed     = Color(1.00, 1.00, 0.00)
	t.bg_disabled    = Color(0.10, 0.10, 0.10)
	t.bg_checked     = Color(1.00, 1.00, 0.00)
	t.border_normal  = Color(1.00, 1.00, 1.00)
	t.border_focused = Color(1.00, 1.00, 0.00)
	t.text_normal    = Color(1.00, 1.00, 1.00)
	t.text_disabled  = Color(0.50, 0.50, 0.50)
	t.accent         = Color(1.00, 1.00, 0.00)
	t.slider_track   = Color(0.20, 0.20, 0.20)
	t.slider_thumb   = Color(1.00, 1.00, 0.00)
	t.text_size      = 20
	t.border_width   = 0.006
	return t
