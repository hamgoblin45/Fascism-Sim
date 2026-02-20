extends Node

signal guest_added(npc_data: NPCData)
signal guest_removed(npc_data: NPCData)
signal guest_notification(message: String)

@export_group("Guest Assets")
@export var clue_prefabs: Array[PackedScene] # Assign your crumpled paper/dirty dish scenes here

var active_guests: Array[GuestNPC] = []
var idle_spots: Array[Node3D] = []

func _ready():
	await get_tree().process_frame
	_update_idle_spots()
	
	# Listen to time to trigger guest needs and messes
	EventBus.hour_changed.connect(_on_hour_changed)

func _update_idle_spots():
	idle_spots.assign(get_tree().get_nodes_in_group("guest_idle_spots"))

func make_guest(npc: NPC):
	print("GuestManager: %s is now a house guest!" % npc.npc_data.name)
	
	if npc.is_in_group("visitors"):
		npc.remove_from_group("visitors")
	if not npc.is_in_group("guests"):
		npc.add_to_group("guests")
		
	if npc is GuestNPC:
		npc.is_inside_house = true
		active_guests.append(npc)
		
	guest_added.emit(npc.npc_data)
	guest_notification.emit("%s is now hiding in your home." % npc.npc_data.name)
	
	send_to_random_spot(npc)

func send_to_random_spot(npc: NPC):
	if idle_spots.is_empty():
		_update_idle_spots()
	if idle_spots.is_empty(): return
		
	var spot = idle_spots.pick_random()
	npc.command_move_to(spot.global_position)
	await npc.destination_reached
	# npc.anim.play("idle_sitting")

# --- DAILY ROUTINE & CLUES ---

func _on_hour_changed(hour: int):
	for guest in active_guests:
		_process_guest_needs(guest)

func _process_guest_needs(guest: GuestNPC):
	# 1. Spawn Clues (e.g., 20% chance every hour to make a mess)
	if randf() < 0.20 and clue_prefabs.size() > 0:
		_spawn_clue_near_guest(guest)
		
	# 2. Change Locations (Keep the house feeling alive)
	if randf() < 0.50:
		send_to_random_spot(guest)
		
	# 3. Increase Hunger/Stress (Placeholder for next steps)
	# guest.hunger += 10.0
	# guest.stress += 5.0

func _spawn_clue_near_guest(guest: GuestNPC):
	var clue_scene = clue_prefabs.pick_random()
	var clue_instance = clue_scene.instantiate() as GuestClue
	
	# Add to world
	get_tree().current_scene.add_child(clue_instance)
	
	# Position at guest's feet with slight random offset
	var offset = Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
	clue_instance.global_position = guest.global_position + offset
	
	print("GuestManager: %s left a mess behind!" % guest.npc_data.name)
