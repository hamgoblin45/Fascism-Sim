extends NPC
class_name OfficerNPC

enum {INVESTIGATING}

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # Handles standard movement/gravity
	
	if state == INVESTIGATING:
		_handle_investigation(delta)
		move_and_slide()
		return
	
	# SCANNING LOGIC:
	# Allow scanning if Raid is active AND not currently busy investigating.
	# We DO allow scanning while in COMMAND_MOVE (walking to a target).
	if GameState.raid_in_progress and state != INVESTIGATING:
		_scan_for_targets()

func _scan_for_targets():
	# 1. Prioritize Guests (Immediate Arrest)
	var guests = get_tree().get_nodes_in_group("guests")
	for guest in guests:
		if guest.get("is_hidden"): continue
		
		if _can_see_target(guest):
			_arrest_guest(guest)
			return # Stop scanning if we found a person

	# 2. Check Clues (Bark & Flag, but keep moving)
	var clues = get_tree().get_nodes_in_group("clues")
	for clue in clues:
		if clue.get("is_discovered"): continue
		
		if _can_see_target(clue):
			_spot_clue_mid_stride(clue)
			return

func _spot_clue_mid_stride(clue: Node):
	# Don't stop moving, just acknowledge it
	clue.is_discovered = true
	EventBus.clue_found.emit(clue) 
	spawn_bark("What's this mess?")
	# SearchManager/RaidSequence listens to 'clue_found' to raise suspicion

func _arrest_guest(guest: NPC):
	command_stop() # Full stop
	look_at_target(guest)
	spawn_bark("FREEZE!")
	state = INVESTIGATING
	SearchManager.guest_spotted_in_open(self, guest)

func _handle_investigation(_delta):
	pass
