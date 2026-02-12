extends Node

@export var major_npc: NPC
@export var search_grunt_npc: NPC
@export var backup_grunt_npc: NPC
@export var door_blocker_pos: Node3D # Where the Major stands initially
@export var major_stand_aside_pos: Node3D # Where Major moves to let Grunt in

@export var front_door: Node3D

var door_answered: bool = false
var countdown_active: bool = false

func _ready() -> void:
	EventBus.raid_starting.connect(start_raid_event)
	EventBus.answering_door.connect(answer_door)

func start_raid_event():
	print("RAID STARTING!!!! 20 Second Countdown initiated")
	# Setup
	GameState.raid_in_progress = true
	door_answered = false
	
	major_npc.global_position = door_blocker_pos.global_position
	major_npc.look_at_target(null)
	major_npc.rotation = door_blocker_pos.rotation
	
	search_grunt_npc.global_position = door_blocker_pos.global_position + (Vector3.BACK * 2.0)
	#Set a position for the backup grunt
	
	# Lock NPCs
	major_npc.command_stop() # Ensure everyone ignores schedules
	search_grunt_npc.command_stop()
	#backup_grunt_npc.command_stop()
	
	_run_countdown(20.0)
	
	# Wait for player interaction
	major_npc.state = major_npc.WAIT

func _run_countdown(seconds: float):
	countdown_active = true
	var time_left = seconds
	
	while time_left > 0:
		if door_answered:
			countdown_active = false
			return # Exit loop if player answers door
		
		# Periodic Barks/Knocks
		if int(time_left) % 5 == 0:
			major_npc.spawn_bark("OPEN THE DOOR!")
			# Add knocking sound here
			#AudioManager.play_spatial("door_knock", major_npc.global_position)
		
		EventBus.raid_timer_updated.emit(time_left)
		
		await get_tree().create_timer(1.0).timeout
		time_left -= 1
	
	if not door_answered:
		_force_entry()

func _force_entry():
	door_answered = true # Prevents answering the door after time expires
	print("RaidSequence: TIMER EXPIRED. FORCING ENTRY!!!")
	
	# Penalty
	GameState.regime_suspicion += 20.0
	EventBus.stat_changed.emit("suspicion")
	
	major_npc.spawn_bark("THAT'S IT! BREAK IT DOWN!")
	await get_tree().create_timer(1.9).timeout
	front_door.toggle_door(true) # Kick open the door
	
	await get_tree().create_timer(0.9).timeout
	major_npc.spawn_bark("Get over here! Turn out your pockets!")
	_begin_frisk()

func answer_door():
	if door_answered: return # Prevent double-triggering
	door_answered = true
	print("RaidSequence: Answering door")
	
	# Play dialogue
	DialogueManager.start_dialogue("major_search_announce_test", major_npc.npc_data.name)
	await DialogueManager.dialogue_ended
	
	_begin_frisk()

func _begin_frisk():
	# Begin frisk
	EventBus.force_ui_open.emit(true)
	GameState.can_move = false
	
	SearchManager.house_raid_status.emit("The Major is patting you down...")
	SearchManager.start_frisk(GameState.pockets_inventory)
	
	var result = await SearchManager.search_finished # Result will be (caught, item, qty)
	
	EventBus.force_ui_open.emit(false)
	GameState.can_move = true
	
	
	if result[0]: # Caught
		print("Player is naughty and should be punished")
		#_handle_consequences()
	else:
		print("RaidSequence: Calling _send_in_grunt from answer_door")
		_send_in_grunt()

func _send_in_grunt():
	if not GameState.raid_in_progress: return
	
	DialogueManager.start_dialogue("major_raid_frisk_complete", major_npc.npc_data.name)
	await DialogueManager.dialogue_ended
	# Major steps aside
	major_npc.command_move_to(major_stand_aside_pos.global_position)
	await major_npc.destination_reached
	major_npc.look_at_target(GameState.player) # Stare at player
	
	print("RaidSequence: Sending in grunt")
	#Hand control over to the SearchManager
	SearchManager.assigned_searcher = search_grunt_npc
	
	# If you make a "RummageProgressUI" thing, have it instance and attach to searcher here or at the beginning of start_house_raid
	
	SearchManager.start_house_raid()

## Set this up to make it where if a grunt sees a guest that isn't hidden, a particular sequence runs
#func _physics_process(delta: float) -> void:
	#if not GameState.raid_in_progress or GameState.hidden_guests.size() < 1: return
	#for npc in GameState.guests:
		#if search_grunt_npc.can_see

func _handle_consequences():
	print("RaidSequence: Player caught with something, idk")
