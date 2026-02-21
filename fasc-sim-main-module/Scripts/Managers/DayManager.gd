extends Node

func _ready():
	# Listen for the normal sleep event
	EventBus.end_day.connect(_on_end_day_normal)

func _on_end_day_normal():
	process_transition(false)

func process_transition(was_arrested: bool):
	print("DayManager: Processing Day Transition. Arrested: ", was_arrested)
	
	# 1. Update Player Stats
	if was_arrested:
		# Penalized Wake Up
		GameState.hp = 50.0
		GameState.energy = 50.0
		GameState.hunger = 50.0 # Assuming 100 is full and 0 is starving
		_confiscate_inventory()
	else:
		# Rested Wake Up
		GameState.hp = 100.0
		GameState.energy = 100.0
		GameState.hunger = 100.0 
	
	# Emit signals to update your HUD bars
	EventBus.stat_changed.emit("hp")
	EventBus.stat_changed.emit("energy")
	EventBus.stat_changed.emit("hunger")
	
	# 2. Advance Time
	# GameState.day += 1 # Uncomment if you track days
	GameState.hour = 8 # Wake up at 8:00 AM
	GameState.minute = 0
	
	# Reset global flags
	GameState.raid_in_progress = false
	
	# 3. Notify the world (ShopManager will generate new stock, Guests will get hungrier)
	EventBus.day_changed.emit()

func _confiscate_inventory():
	var inv = GameState.pockets_inventory
	if not inv: return
	
	for i in range(inv.slots.size()):
		if inv.slots[i] != null:
			inv.slots[i] = null
			EventBus.inventory_item_updated.emit(inv, i)
			
	print("DayManager: All player items confiscated.")
