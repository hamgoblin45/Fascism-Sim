extends Node

@export var major_npc: NPC
@export var search_grunt_npc: NPC
@export var backup_grunt_npc: NPC
@export var door_blocker_pos: Node3D # Where the Major stands initially
@export var major_stand_aside_pos: Node3D # Where Major moves to let Grunt in

@onready var search_manager: Node = %SearchManager

func _ready() -> void:
	EventBus.raid_starting.connect(start_raid_event)
	EventBus.answering_door.connect(answer_door)
	Dialogic.timeline_ended.connect(_send_in_grunt)

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
	DialogueManager.start_dialogue("major_search_announce_test")
	#await Dialogic.timeline_ended
	#
	#
	#
	#_send_in_grunt()

func _send_in_grunt():
	if not GameState.raid_in_progress:
		print("Raid is not in progress")
		return
	# Major steps aside
	major_npc.command_move_to(major_stand_aside_pos.global_position)
	await major_npc.destination_reached
	major_npc.look_at_target(GameState.player) # Stare at player
	
	print("RaidSequence: Sending in grunt")
	#Hand control over to the SearchManager
	search_manager.assigned_searcher = search_grunt_npc
	
	
	
	search_manager.start_house_raid()
	
