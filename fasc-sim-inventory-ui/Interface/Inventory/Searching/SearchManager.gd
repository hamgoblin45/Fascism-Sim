extends Node

signal search_step_started(index: int, duration: float)
signal search_finished(caught: bool, item: InventoryItemData, qty: int)

var current_search_inventory: InventoryData = null
var current_search_index: int = -1 # Where the searcher's "hands" are
var suspicion_level: float = 0.0 # Increases when moving an item mid search ( I think)

var patience: float = 15.0 # How long the search will take
var thoroughness: float = 0.5 # 0.0 to 1.0 (searcher's skill, Suspicion will directly impact this)
var is_searching: bool = false
var is_silent_search: bool = false # Determines if search if player inv or not

var temp_elapse_time: float = 0.0 #TESTING

func start_search(inventory: InventoryData):
	print("SearchManager: STARTING SEARCH!")
	is_searching = true
	suspicion_level = 0.0
	var elapsed_time = 0.0
	temp_elapse_time = elapsed_time
	
	current_search_inventory = inventory
	
	for i in range(inventory.slot_datas.size()):
		if not is_searching or elapsed_time >= patience:
			break
		
		current_search_index = i
		var slot = inventory.slot_datas[i]
		var base_time = 1.5 # The time it takes to search an empty/insignificant slot
		var search_duration = base_time
		
		if slot and slot.item_data:
			search_duration += (slot.item_data.concealability * 0.8) # Takes longer to seach based on how well hidden slot is
			print("SearchManager: %s has a contraband level of %s" % [slot.item_data.name, slot.item_data.contraband_level])
		
		search_step_started.emit(i, search_duration)
		
		# Wait for each slot to be searched before running
		await get_tree().create_timer(search_duration).timeout
		elapsed_time += search_duration
		temp_elapse_time = elapsed_time
		
		if slot and slot.item_data:
			
			if _discovered_contraband(slot.item_data):
				player_busted(slot.item_data, slot.quantity, i)
				
				return
	_finish_search(false, null, 0)
	#search_finished.emit(false, null, 0)
	#is_searching = false

func start_external_search(inventory: InventoryData, thoroughness_modifier: float = 0.5):
	is_searching = true
	is_silent_search = true
	thoroughness = thoroughness_modifier
	
	print("SearchManager: NPC is beginning to search ", inventory)
	
	for i in range(inventory.slot_datas.size()):
		if not is_searching: break
		
		var slot = inventory.slot_datas[i]
		
		var search_duration = 1.0
		if slot and slot.item_data:
			search_duration += (slot.item_data.concealability * 0.5)
		
		# Simulates taking the time to search each slot
		await get_tree().create_timer(search_duration).timeout
		
		if slot and slot.item_data:
			if _discovered_contraband(slot.item_data):
				player_busted_external(inventory, slot, i)
				return
		
		print("SearchManager: NPC finished search, found nothing")
		is_searching = false
		is_silent_search = false

func _discovered_contraband(item: InventoryItemData) -> bool:
	
	if item.contraband_level <= GameState.regime_tolerance:
		return false
	
	# Higher concealability reduces RNG chance of discovery
	# Thoroughness increases it
	var discovery_chance = (thoroughness) / (item.concealability + 0.1)
	var output = str(discovery_chance * 100)
	print("SearchManager: Chance of contraband being discovered: %s percent" % output)
	return randf() < discovery_chance

func _finish_search(caught: bool, item: InventoryItemData, qty: int):
	print("SearchManager: search finished. Caught: ", caught)
	is_searching = false
	current_search_inventory = null
	current_search_index = -1
	search_finished.emit(caught, item, qty)

func player_busted(item: InventoryItemData, qty: int, index: int):
	print("SearchManager: PLAYER BUSTED with ", item.name)
	var penalty = (item.contraband_level * qty) * 2.5 # How much suspicion will be added based on the amount of contraband / contraband lvl
	GameState.suspicion += penalty
	GameState.world_flags["busted_with_contraband"] = true
	EventBus.world_changed.emit("busted_with_contraband", true)
	
	# Confiscation
	if current_search_inventory:
		current_search_inventory.slot_datas[index] = null
		EventBus.inventory_item_updated.emit(current_search_inventory, index)
	
	is_searching = false
	search_finished.emit(true, item, qty)

func player_busted_external(inventory: InventoryData, slot: InventorySlotData, index: int):
	var penalty = (slot.item_data.contraband_level * slot.quantity) * 2.5 # How much suspicion will be added based on the amount of contraband / contraband lvl
	GameState.suspicion += penalty
	
	is_searching = false
	search_finished.emit(true, slot.item_data, slot.quantity)
	# Confiscation
	inventory.slot_datas[index] = null
	EventBus.inventory_item_updated.emit(inventory, index)
