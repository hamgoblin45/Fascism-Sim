extends NPC
class_name OfficerNPC


func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Calls parent's physics process as well
	
	if GameState.raid_in_progress and state != IDLE:
		_scan_for_guests()

func _scan_for_guests():
	# Optimization: Eventually we will cut this down to not be every frame but that's how it is now for simplicity
	var guests = get_tree().get_nodes_in_group("guests")
	
	for guest in guests:
		# Skip if guest is hiding; shouldn't need this since the guest queues free but if we change that use this
		if guest.get("is_hidden"): continue
		
		if _can_see_target(guest):
			_arrest_guest(guest)

func _arrest_guest(guest: NPC):
	command_stop()
	look_at_target(guest)
	spawn_bark("FREEZE!")
	SearchManager.guest_spotted_in_open(self, guest)
