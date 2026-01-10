extends Control


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_start_dialogue()

func _start_dialogue():
	# Check if a dialogue is already running
	if Dialogic.current_timeline != null:
		return
	
	Dialogic.start("timeline")
	get_viewport().set_input_as_handled()
