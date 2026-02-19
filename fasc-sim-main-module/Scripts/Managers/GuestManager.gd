extends Node

signal guest_added(npc_data: NPCData)
signal guest_removed(npc_data: NPCData)
signal guest_notification(message: String)

var active_guests: Array[GuestNPC] = []
var idle_spots: Array[Node3D] = []

func _ready():
	# Wait a frame to let the level load, then find all idle spots
	await get_tree().process_frame
	_update_idle_spots()

func _update_idle_spots():
	idle_spots.assign(get_tree().get_nodes_in_group("guest_idle_spots"))

func make_guest(npc: NPC):
	print("GuestManager: %s is now a house guest!" % npc.npc_data.name)
	
	# Make sure they are recognized as a guest
	if npc.is_in_group("visitors"):
		npc.remove_from_group("visitors")
	if not npc.is_in_group("guests"):
		npc.add_to_group("guests")
		
	# Ensure the node is actually using GuestNPC.gd so we have access to hiding functions
	if npc is GuestNPC:
		npc.is_inside_house = true
		active_guests.append(npc)
	else:
		push_warning("GuestManager: %s was made a guest, but their node doesn't use GuestNPC.gd!" % npc.npc_data.name)
	
	# Update UI
	guest_added.emit(npc.npc_data)
	guest_notification.emit("%s is now hiding in your home." % npc.npc_data.name)
	
	# Send them to make themselves at home
	send_to_random_spot(npc)

func send_to_random_spot(npc: NPC):
	if idle_spots.is_empty():
		_update_idle_spots()
	
	if idle_spots.is_empty():
		print("GuestManager: No 'guest_idle_spots' found in the scene!")
		return
		
	var spot = idle_spots.pick_random()
	print("GuestManager: Sending %s to %s" % [npc.npc_data.name, spot.name])
	
	# We use the dynamic nav command we built earlier!
	npc.command_move_to(spot.global_position)
	
	# Optional: Wait for them to arrive, then play an animation
	await npc.destination_reached
	print("GuestManager: %s arrived at their spot." % npc.npc_data.name)
	
	# If your spots have specific animations attached, you could read them here
	# npc.anim.play("sitting") 

# --- STUBS FOR FUTURE SYSTEMS ---
func _on_hour_changed(hour: int):
	# Loop through active_guests
	# Increase hunger/stress
	# Maybe command them to move to a new idle spot so the house feels alive
	pass
