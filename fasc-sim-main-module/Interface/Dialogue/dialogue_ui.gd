extends Control

@onready var test_image_display: TextureRect = $TestImageDisplay


func _start_dialogue():
	# Check if a dialogue is already running
	if Dialogic.current_timeline != null:
		return
	
	Dialogic.start("timeline")
	get_viewport().set_input_as_handled()
