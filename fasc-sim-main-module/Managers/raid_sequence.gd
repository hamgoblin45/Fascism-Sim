extends Node

@export var major_npc: NPC
@export var search_grunt_npc: NPC
@export var backup_grunt_npc: NPC
@export var door_blocker_pos: Node3D # Where the Major stands initially
@export var major_stand_aside_pos: Node3D # Where Major moves to let Grunt in


func _ready() -> void:
	EventBus.raid_starting.connect(start_raid_event)
	EventBus.answering_door.connect(answer_door)

func start_raid_event():
	print("RAID STARTING!!!!")
	# Setup
	GameState.raid_in_progress = true
	major_npc.global_position = door_blocker_pos.global_position
	major_npc.look_at_target(null)
	major_npc.rotation = door_blocker_pos.rotation
	
	search_grunt_npc.global_position = door_blocker_pos.global_position + (Vector3.BACK * 2.0)
	#Set a position for the backup grunt
	
	# Lock NPCs
	major_npc.command_stop() # Ensure everyone ignores schedules
	search_grunt_npc.command_stop()
	#backup_grunt_npc.command_stop()
	
	# Wait for player interaction
	major_npc.state = major_npc.WAIT

func answer_door():
	print("RaidSequence: Answering door")
	# Play dialogue
	DialogueManager.start_dialogue("major_search_announce_test", major_npc.npc_data.name)
	await DialogueManager.dialogue_ended
	
	# Begin frisk
	EventBus.force_ui_open.emit(true)
	
	SearchManager.house_raid_status.emit("The Major is patting you down...")
	SearchManager.start_frisk(GameState.pockets_inventory)
	
	var result = await SearchManager.search_finished # Result will be (caught, item, qty)
	var caught = result[0]
	
	EventBus.force_ui_open.emit(false)
	
	if caught:
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
	

func _handle_consequences():
	print("RaidSequence: Player caught with something, idk")
