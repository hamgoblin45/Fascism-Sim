extends Node






func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
func _on_dialogic_signal(arg: Dictionary):
	match arg["signal_name"]:
		"show_image":
			EventBus.dialogue_show_image.emit(arg["image_path"])
		"kick_balls":
			EventBus.kick_balls.emit()
