extends Node

func _ready():
	EventBus.end_day.connect(_on_end_day_normal)

func _on_end_day_normal():
	# 1. Disable player movement while falling asleep
	GameState.can_move = false 
	
	# FIX: Just await the function itself, because it already returns the signal!
	await DayTransition.fade_out_for_sleep()
	
	# 3. Process the math
	process_transition(false)

func process_transition(was_arrested: bool):
	print("DayManager: Processing Day Transition. Arrested: ", was_arrested)
	
	# --- STAT UPDATES ---
	if was_arrested:
		GameState.hp = 50.0
		GameState.energy = 50.0
		GameState.hunger = 50.0 
		_confiscate_inventory()
	else:
		GameState.hp = 100.0
		GameState.energy = 100.0
		GameState.hunger = 100.0 
	
	EventBus.stat_changed.emit("hp")
	EventBus.stat_changed.emit("energy")
	EventBus.stat_changed.emit("hunger")
	
	# --- WORLD UPDATES ---
	# GameState.day += 1 
	GameState.hour = 8 
	GameState.minute = 0
	GameState.raid_in_progress = false
	
	# --- TELEPORT PLAYER ---
	var spawns = get_tree().get_nodes_in_group("bed_spawn")
	if spawns.size() > 0:
		# Move the player
		GameState.player.global_position = spawns[0].global_position
		GameState.player.global_rotation = spawns[0].global_rotation 
		
		if GameState.player.has_node("Head"):
			GameState.player.get_node("Head").rotation.x = 0
	else:
		push_warning("DayManager: No node found in 'bed_spawn' group! Teleport failed.")

	# --- NOTIFY WORLD ---
	EventBus.day_changed.emit()

	# --- WAKE UP ---
	# Wait a second in the darkness to let the tension/rest sink in
	await get_tree().create_timer(1.0).timeout
	
	# Fade back in to the morning light using the renamed UI manager
	DayTransition.fade_in()
	GameState.can_move = true

func _confiscate_inventory():
	var inv = GameState.pockets_inventory
	if not inv: return
	
	for i in range(inv.slots.size()):
		if inv.slots[i] != null:
			inv.slots[i] = null
			EventBus.inventory_item_updated.emit(inv, i)
			
	print("DayManager: All player items confiscated.")
