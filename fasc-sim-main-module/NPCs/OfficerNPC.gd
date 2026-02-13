extends NPC
class_name OfficerNPC

enum {INVESTIGATING}

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Calls parent's physics process as well
	
	if state == INVESTIGATING:
		_handle_investigation(delta)
		move_and_slide()
		return
		
	if GameState.raid_in_progress and state != IDLE:
		if state != INVESTIGATING:
			_scan_for_targets()


func _scan_for_targets():
	# Optimization: Eventually we will cut this down to not be every frame but that's how it is now for simplicity
	var guests = get_tree().get_nodes_in_group("guests")
	
	for guest in guests:
		# Skip if guest is hiding; shouldn't need this since the guest queues free but if we change that use this
		if guest.get("is_hidden"): continue
		
		if _can_see_target(guest):
			_arrest_guest(guest)
			return
	
	var clues = get_tree().get_nodes_in_group("clues")
	for clue in clues:
		if clue.is_discovered: continue # Don't worry about clues already found
		
		if _can_see_target(clue):
			_start_investigation(clue)
			return

func _start_investigation(clue: GuestClue):
	command_stop()
	state = INVESTIGATING
	
	clue.on_spotted(self)
	
	await get_tree().create_timer(clue.investigation_time).timeout
	
	# Resume search
	# If raid still ongoing, go back to IDLE. SearchManager will likely move us shortly
	if state == INVESTIGATING:
		state = IDLE

func _handle_investigation(_delta):
	# Keep looking at target here?
	pass


func _arrest_guest(guest: NPC):
	command_stop()
	look_at_target(guest)
	spawn_bark("FREEZE!")
	SearchManager.guest_spotted_in_open(self, guest)
