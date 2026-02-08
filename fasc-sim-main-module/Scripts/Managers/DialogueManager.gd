extends Node
# Used to call functions across the game from dialogue, especially Objectives and score adjustments (Suspicion, resistance, etc)



func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)


func start_dialogue():
	# Check if a dialogue is already running
	if Dialogic.current_timeline != null:
		return
	
	Dialogic.start("timeline")
	get_viewport().set_input_as_handled()

# Call this func from Dialogic: DialogueBridge.accept_quest("path to objective")
func accept_objective(path: String):
	var obj = load(path)
	if obj:
		EventBus.advance_objective.emit(obj)

# This is used to confirm player has an objective before show a particular dialogue branch
func is_objective_complete(id: String) -> bool:
	for obj in GameState.objectives:
		if obj.id == id:
			return obj.complete
	return false


	
func _on_dialogic_signal(arg: Dictionary):
	match arg["signal_name"]:
		"show_image":
			EventBus.dialogue_show_image.emit(arg["image_path"])
		"kick_balls":
			EventBus.kick_balls.emit()
