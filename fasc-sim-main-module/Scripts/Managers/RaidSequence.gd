extends Node
class_name RaidSequence

@export var major_npc: NPC
@export var search_grunt_npc: NPC
@export var door_blocker_pos: Node3D
@export var major_stand_aside_pos: Node3D
@export var front_door: Node3D 

var door_answered: bool = false
var countdown_active: bool = false

func _ready() -> void:
	EventBus.raid_starting.connect(start_raid_event)
	EventBus.answering_door.connect(answer_door)

func start_raid_event() -> void:
	print("RaidSequence: RAID STARTING! 20s Countdown.")
	GameState.raid_in_progress = true
	door_answered = false
	
	# Setup positions
	if door_blocker_pos:
		major_npc.global_position = door_blocker_pos.global_position
		major_npc.look_at_target(front_door) # Look at door
		search_grunt_npc.global_position = door_blocker_pos.global_position + (Vector3.BACK * 2.0)
	
	# Stop AI
	major_npc.command_stop()
	search_grunt_npc.command_stop()
	major_npc.state = major_npc.WAIT
	
	_run_countdown(20.0)

func _run_countdown(seconds: float) -> void:
	countdown_active = true
	var time_left = seconds
	
	while time_left > 0:
		if door_answered:
			countdown_active = false
			return
		
		# Barks every 5 seconds
		if int(time_left) % 5 == 0:
			major_npc.spawn_bark("OPEN THE DOOR!")
			# AudioManager.play_spatial("knock", major_npc.global_position)
		
		EventBus.raid_timer_updated.emit(time_left)
		await get_tree().create_timer(1.0).timeout
		time_left -= 1.0
	
	if not door_answered:
		_force_entry()

func _force_entry() -> void:
	door_answered = true
	print("RaidSequence: FORCING ENTRY!")
	
	GameState.regime_suspicion += 20.0
	EventBus.stat_changed.emit("suspicion")
	
	major_npc.spawn_bark("BREAK IT DOWN!")
	await get_tree().create_timer(1.9).timeout
	
	if front_door.has_method("toggle_door"):
		front_door.toggle_door(true)
	
	await get_tree().create_timer(0.9).timeout
	major_npc.spawn_bark("Hands where I can see them!")
	_begin_frisk()

func answer_door() -> void:
	if door_answered: return
	door_answered = true
	print("RaidSequence: Answering door.")
	
	# Use DialogueManager to handle mouse mode
	DialogueManager.start_dialogue("major_search_announce_test", major_npc.npc_data.name)
	await DialogueManager.dialogue_ended
	
	_begin_frisk()

func _begin_frisk() -> void:
	EventBus.force_ui_open.emit(true)
	GameState.can_move = false
	SearchManager.house_raid_status.emit("The Major is patting you down...")
	
	# Start Frisk Logic in Manager
	SearchManager.start_frisk(GameState.pockets_inventory)
	
	# Wait for signal (caught, item, qty)
	var result = await SearchManager.search_finished 
	
	EventBus.force_ui_open.emit(false)
	GameState.can_move = true
	
	var caught = result[0] # Signal argument 0
	
	if caught:
		# SearchManager handles interrogation trigger
		print("RaidSequence: Player caught during frisk.")
	else:
		_send_in_grunt()

func _send_in_grunt() -> void:
	if not GameState.raid_in_progress: return
	
	DialogueManager.start_dialogue("major_raid_frisk_complete", major_npc.npc_data.name)
	await DialogueManager.dialogue_ended
	
	# Major moves aside
	if major_stand_aside_pos:
		major_npc.command_move_to(major_stand_aside_pos.global_position)
		await major_npc.destination_reached
		major_npc.look_at_target(GameState.player)
	
	print("RaidSequence: Sending in Grunt.")
	SearchManager.assigned_searcher = search_grunt_npc
	SearchManager.start_house_raid()
