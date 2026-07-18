extends Node3D

const Gallery = preload("res://addons/godot-charts/assets/visual/visual_asset_gallery_3d.gd")

@onready var status_label: Label3D = $StatusLabel


func _ready() -> void:
	var gallery := Gallery.new()
	gallery.name = "VisualAssetGallery3D"
	gallery.use_webxr_performance_theme = true
	gallery.columns = 6
	gallery.spacing = Vector3(0.5, 0.0, 0.42)
	gallery.position = Vector3(-1.25, 1.15, 0.0)
	add_child(gallery)

	var snapshot := gallery.gallery_snapshot()
	status_label.text = "Visual asset roles: %d" % int(snapshot["asset_count"])
	print("Visual asset gallery ready: ", snapshot)
