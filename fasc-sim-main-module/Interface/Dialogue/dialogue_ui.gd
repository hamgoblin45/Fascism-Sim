extends Control

@onready var test_image_display: TextureRect = $TestImageDisplay



#func _ready():
	## to TEST the ability to call funcs from dialogue
	#EventBus.dialogue_show_image.connect(_show_image)
	#EventBus.kick_balls.connect(_kicked_in_the_balls)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_start_dialogue()

func _start_dialogue():
	# Check if a dialogue is already running
	if Dialogic.current_timeline != null:
		return
	
	Dialogic.start("timeline")
	get_viewport().set_input_as_handled()


### to TEST the ability to call funcs from dialogue
#func _show_image(image_path: String):
	#test_image_display.texture = load(image_path)
	#test_image_display.show()
