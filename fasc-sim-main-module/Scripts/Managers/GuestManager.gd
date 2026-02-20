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
	if not guest.is_inside_house: return

	# 1. Increase Needs
	guest.hunger = min(100.0, guest.hunger + 5.0) # Gets hungrier every hour
	guest.stress = min(100.0, guest.stress + 2.0) # Base stress increase
	
	# If they are starving, stress skyrockets
	if guest.hunger >= 80.0:
		guest.stress = min(100.0, guest.stress + 10.0)
		guest.spawn_bark("I'm so hungry...")

	# 2. Spawn Clues (Messes)
	var mess_chance = 0.10 # Base 10% chance per hour
	if guest.stress >= 80.0:
		mess_chance = 0.40 # 40% chance if highly stressed/panicking
		
	if randf() < mess_chance and clue_prefabs.size() > 0:
		_spawn_clue_near_guest(guest)
		
	# 3. Change Locations to make the house feel alive
	if randf() < 0.50 and not guest.is_hidden:
		send_to_random_spot(guest)

func _spawn_clue_near_guest(guest: GuestNPC):
	var clue_scene = clue_prefabs.pick_random()
	var clue_instance = clue_scene.instantiate() as GuestClue
	
	# Add to world
	get_tree().current_scene.add_child(clue_instance)
	
	# Position at guest's feet with slight random offset
	var offset = Vector3(randf_range(-0.5, 0.5), 0.5, randf_range(-0.5, 0.5))
	clue_instance.global_position = guest.global_position + offset
	
	print("GuestManager: %s left a mess behind!" % guest.npc_data.name)
