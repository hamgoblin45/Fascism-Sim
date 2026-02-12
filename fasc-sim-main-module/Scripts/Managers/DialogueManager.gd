extends Node
# Used to call functions across the game from dialogue, especially Objectives and score adjustments (Suspicion, resistance, etc)

signal dialogue_ended
signal dialogue_started

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func start_dialogue(timeline_key: String, npc_name: String = ""):
	# Check if a dialogue is already running
	if Dialogic.current_timeline != null:
		return
	
	if npc_name != "":
		Dialogic.VAR.CurrentNPC = npc_name
		
	print("DialogueManager: Starting dialogue timeline: ", timeline_key)
	
	Dialogic.start(timeline_key)
	
	get_viewport().set_input_as_handled()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.in_dialogue = true
	dialogue_started.emit()

func _on_timeline_ended():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.in_dialogue = false
	
	dialogue_ended.emit()

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
		"follow_player":
			EventBus.follow_player.emit(GameState.talking_to, true)
