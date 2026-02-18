extends Node
# Used to call functions across the game from dialogue, especially Objectives and score adjustments (Suspicion, resistance, etc)

signal dialogue_ended
signal dialogue_started
signal interrogation_started
signal dialogue_choice_selected(choice_id: String)

func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func start_dialogue(timeline_key: String, npc_name: String = ""):
	if Dialogic.current_timeline != null: return
	
	if npc_name != "":
		Dialogic.VAR.CurrentNPC = npc_name
		
	print("DialogueManager: Starting dialogue timeline: ", timeline_key)
	Dialogic.start(timeline_key)
	
	get_viewport().set_input_as_handled()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.in_dialogue = true
	GameState.can_move = false
	dialogue_started.emit()

func _on_timeline_ended():
	GameState.in_dialogue = false
	GameState.can_move = true
	
	# FIX: Only recapture mouse if we are NOT shopping
	if not GameState.shopping:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
		"choice_selected":
			dialogue_choice_selected.emit(arg["choice_id"])
		"open_shop":
			if arg["shop_inventory"]:
				var inv = load(arg["shop_inventory"])
				EventBus.open_specific_shop.emit(inv, false)
		#"visitor_leave":
			#EventBus.visitor_leave_requested.emit()
