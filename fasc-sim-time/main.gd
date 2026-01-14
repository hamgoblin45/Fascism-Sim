extends Node3D



func _ready() -> void:
	EventBus.main_scene_loaded.emit()
