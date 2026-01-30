extends Node

signal search_step_started(index: int, duration: float)
signal search_finished(caught: bool, item: InventoryItemData, qty: int)


var patience: float = 25.0 # How long the search will take
var thoroughness: float = 0.5 # 0.0 to 1.0 (searcher's skill, Suspicion will directly impact this)
var is_searching: bool = false

func start_search(inventory: InventoryData):
	is_searching = true
	var elapsed_time = 0.0
	
	for i in range(inventory.slot_datas.size()):
		if not is_searching or elapsed_time >= patience:
			break
		
		var slot = inventory.slot_datas[i]
		var base_time = 1.5 # The time it takes to search an empty/insignificant slot
		var search_duration = base_time
		
		if slot and slot.item_data:
			search_duration += (slot.item_data.concealability * 0.8) # Takes longer to seach based on how well hidden slot is
		
		search_step_started.emit(i, search_duration)
		
		# Wait for each slot to be searched before running
		await get_tree().create_timer(search_duration).timeout
		elapsed_time += search_duration
		
		if slot and slot.item_data:
			if _check_discovery(slot.item_data):
				search_finished.emit(true, slot.item_data, slot.quantity)
				is_searching = false
				return
		
	search_finished.emit(false, null, 0)
	is_searching = false

func _check_discovery(item: InventoryItemData) -> bool:
	if item.contraband_level == 0: return false
	
	# Higher concealability reduces RNG chance of discovery
	# Thoroughness increases it
	var discovery_chance = (item.contraband_level * thoroughness) / (item.concealability + 0.1)
	return randf() < discovery_chance
	
