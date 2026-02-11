extends Node

signal search_step_started(index: int, duration: float)
signal search_finished(caught: bool, item: InventoryItemData, qty: int)
signal house_raid_status(message: String) # For the sake of UI. "The guards are checking the pantry..."

var current_search_inventory: InventoryData = null
var current_search_index: int = -1 # Where the searcher's "hands" are
var suspicion_level: float = 0.0 # Increases when moving an item mid search ( I think)

var patience: float = 15.0 # How long the search will take
var thoroughness: float = 0.5 # 0.0 to 1.0 (searcher's skill, Suspicion will directly impact this)
var is_searching: bool = false
var is_silent_search: bool = false # Determines if search if player inv or not

var temp_elapse_time: float = 0.0 #TESTING
var active_clues: Array[GuestClue] = []

var assigned_searcher: NPC = null


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
		#is_searching = false
		is_silent_search = false

func start_house_raid():
	is_searching = true
	# Start actually searching the house
	var hiding_spots: Array[HidingSpot]
	hiding_spots.assign(get_tree().get_nodes_in_group("hiding_spots"))
	var containers: Array[Interactable]
	containers.assign(get_tree().get_nodes_in_group("house_containers"))
	var clues: Array[GuestClue]
	clues.assign(get_tree().get_nodes_in_group("guest_clues"))
	active_clues = clues
	print("SearchManager: HOUSE RAID COMMENCING")
	
	# Determine intensity
	# Base: search 3 items, +1 for every 10 suspicion. Max is everything
	var total_targets = hiding_spots.size() + containers.size()
	var search_count = clamp(3 + int(GameState.suspicion / 10.0), 3, total_targets)
	print("SearchManager: About to search %s of %s total targets" % [search_count, total_targets])
	
	# Sort by the "obviousness" of spots
	# Guards should search things closest and "easy" first
	var potential_targets = []
	potential_targets.append_array(hiding_spots)
	potential_targets.append_array(containers)
	potential_targets.append_array(clues)
	
	potential_targets.sort_custom(func(a,b):
		var a_score = a.concealment_score if a is HidingSpot else 0.1 # Containers are obvious
		var b_score = b.concealment_score if b is HidingSpot else 0.1
		return a_score < b_score
		)
	
	# Execution loop
	for i in range(search_count):
		if not is_searching: break
		
		var target = potential_targets.pop_front() # get the next target
		#house_raid_status.emit("Searching ", target.name) # Need a target.name for this to work
		
		if assigned_searcher:
			print("SearchManager: Searcher moving to next search target")
			# Command NPC to walk to target
			var move_pos = target.global_position + (Vector3(1,0,1).normalized() * 1.0)
			assigned_searcher.command_move_to(move_pos)
			
			await assigned_searcher.destination_reached
			print("SearchManager: Searcher arrived at target location")
			# Face the object
			assigned_searcher.look_at_node.look_at(target.global_position)
			
			# Search anim
			assigned_searcher.state = assigned_searcher.ANIMATING
			# assigned_searcher.anim.play("search_low" if target is HidingSpot else "search_standing")
		
		# If a guard walks past a GuestClue
		for clue in active_clues:
			if assigned_searcher.global_position.distance_to(clue.global_position) < 2.0: # Figure out what to add as "guard" here
				print("Guard noticed a GuestClue")
				search_count += 2 # They will search more spots now
				thoroughness += 0.1
				#guard.spawn_bark("Who left this here") or something liek that
		
		## Pick one of the first 3 possible targets
		#var slice = potential_targets.slice(0,3)
		#slice.shuffle()
		#var current_target = slice[0]
		#potential_targets.erase(current_target)
		#
		#house_raid_status.emit("Guards are inspecting the " + current_target.name)
		
		#Perform the actual check
		if target is HidingSpot:
			await _search_hiding_spot(target)
		else:
			# It's a container
			print("Searching a container")
			var inv = target.get_parent().container_inventory
			await _search_container_during_raid(inv, thoroughness)
	
	_finish_house_raid(hiding_spots)

func _search_container_during_raid(inventory: InventoryData, thoroughness_mod: float):
	#print("Searching ", inventory)
	for i in range(inventory.slot_datas.size()):
		# Check if the raid was cancelled (busted, etc) 
		if not is_searching:
			break
		
		var slot = inventory.slot_datas[i]
		
		# Calculate time
		var search_duration = 1.0
		if slot and slot.item_data:
			search_duration += (slot.item_data.concealability * 0.5)
		
		print("Searching for ", search_duration)
		await get_tree().create_timer(search_duration).timeout
		
		
		if slot and slot.item_data:
			if _discovered_contraband(slot.item_data):
				player_busted_external(inventory, slot, i)
				return
	print("SearchManager: Container cleared")

func _finish_house_raid(hiding_spots: Array[HidingSpot]):
	print("SearchManager: Finishing house raid")
	if assigned_searcher:
		assigned_searcher.command_move_to(Vector3(0, 0, 50)) # Far coords, change to specific pos to polish it
		await assigned_searcher.destination_reached
		GameState.raid_in_progress = false
		assigned_searcher.queue_free()
	print("SearchManager: Guards have left the house")
	# Automatically have guests come out from hiding
	for spot in hiding_spots:
		if spot.occupant:
			await get_tree().create_timer(2.5).timeout
			spot._extract_occupant()
	
	# Lower suspicion slightly after a "clean" search
	GameState.suspicion -= 5.0

func _search_hiding_spot(spot: HidingSpot):
	print("SearchManager: Searching hiding spot")
	# Time it takes to search
	var dur = 3.0 + (spot.concealment_score * 5.0)
	await get_tree().create_timer(dur).timeout
	
	if spot.occupant:
		# Roll to see if the occupant is discovered
		var discovery_chance = (thoroughness + (GameState.suspicion / 100.0)) / (spot.concealment_score + 0.1)
		
		if randf() < discovery_chance:
			_guest_captured(spot.occupant)
			is_searching = false

func _guest_captured(npc: NPC):
	print("SearchManager: GUEST DISCOVERED! ", npc.npc_data.name)
	var flag_name = npc.npc_data.id + "_captured"
	GameState.world_flags[flag_name] = true

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
	var penalty = (slot.item_data.contraband_level * slot.quantity) * 2.5 # Maybe less suspicion because item isn't on the player's person?
	GameState.suspicion += penalty
	
	is_searching = false
	search_finished.emit(true, slot.item_data, slot.quantity)
	# Confiscation
	inventory.slot_datas[index] = null
	EventBus.inventory_item_updated.emit(inventory, index)
