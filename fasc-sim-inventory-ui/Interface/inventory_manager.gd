extends Node
# Holds all the inter-connected inventory logic

@export var pockets_inventory_data: InventoryData
@export var external_inventory_data: InventoryData # These should be set by signals but using export for testing
@export var shop_inventory_data: InventoryData # These should be set by signals but using export for testing

var grabbed_slot_data: InventorySlotData
var source_inventory: InventoryData
var pending_grab_slot_data: InventorySlotData
var pending_grab_slot_ui: PanelContainer
#var grab_slot_data: InventorySlotData

@onready var inv_ui: Control = $".."
@onready var pockets_inventory_ui: PanelContainer = %PocketsInventoryUI
var pocket_slot_container: GridContainer
@onready var external_inventory: PanelContainer = %ExternalInventory
@onready var shop_ui: PanelContainer = %ShopUI
@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI
@onready var grab_timer: Timer = %GrabTimer


func _ready() -> void:
	EventBus.inventory_interacted.connect(_on_inventory_interact)
	EventBus.adding_item.connect(_add_item_to_inventory)
	EventBus.removing_item.connect(_remove_item_from_inventory)
	EventBus.request_pockets_inventory.connect(_on_pockets_request)
	EventBus.splitting_item_stack.connect(_split_item_stack)
	#EventBus.selling_item.connect(_sell_item)
	#EventBus.using_item.connect(_use_item)
	EventBus.setting_external_inventory.connect(_set_external_inventory)
	
	call_deferred("_set_player_inventory")


func _set_player_inventory():
	# Sets player inventory
	print("InventoryManager: Setting pockets inventory")
	pocket_slot_container = pockets_inventory_ui.slot_container
	GameState.pockets_inventory = pockets_inventory_data
	EventBus.pockets_inventory_set.emit(pockets_inventory_data)
	# If bags added later, emit setup here

func _on_pockets_request():
	print("Manager: UI requested inventory, sending data...")
	EventBus.pockets_inventory_set.emit(pockets_inventory_data)

## -- INVENTORY INTERACTION
func _on_inventory_interact(inv: InventoryData, slot_ui: PanelContainer, slot_data: InventorySlotData, type: String):
	match type:
		"shift_click":
			if slot_data and slot_data.item_data:
				print("InventoryManager: shift click detected, trying to quick transfer...")
				_handle_quick_move(inv, slot_data)
				
		
		"click":
			print("InventoryManager: Click on %s in %s" % [slot_ui, inv])
			# Drop or merge slot if grabbing something
			if grabbed_slot_data and slot_ui is SlotUI:
				# Disable interaction w/ shop if grabbing an item
				
				_handle_drop_or_merge(inv, slot_ui, slot_data)
				return
			#If not grabbing anything, select and start grab timer
			EventBus.select_item.emit(slot_data)
			if slot_data and slot_data.item_data:

				# START GRAB PROCESS
				if slot_ui is SlotUI: # Don't grab shop slots
					_start_grabbing_slot(slot_ui, slot_data)

		"r_click":
			print("InventoryManager: Right-Click on %s in %s" % [slot_ui, inv])
			if grabbed_slot_data and slot_ui is SlotUI:
				# Disable interaction w/ shop if grabbing an item
				if inv == shop_inventory_data:
					return
				var index = slot_ui.get_index()
				
				# If slot is empty, create a new one
				if not slot_data or not slot_data.item_data:
					var new_slot = InventorySlotData.new()
					new_slot.item_data = grabbed_slot_data.item_data
					new_slot.quantity = 1
					
					inv.slot_datas[index] = new_slot # Update resource
					slot_ui.set_slot_data(new_slot) # Update UI
					grabbed_slot_data.quantity -= 1
				
				# If slot matches, increment
				elif slot_data.item_data == grabbed_slot_data.item_data:
					if slot_data.quantity < slot_data.item_data.max_stack_size:
						slot_data.quantity += 1
						grabbed_slot_data.quantity -= 1
						slot_ui.set_slot_data(slot_data)
						
				if grabbed_slot_data.quantity <= 0:
					grabbed_slot_data = null
				
				EventBus.update_grabbed_slot.emit(grabbed_slot_data)
	
		"world_click":
			if grabbed_slot_data:
				_discard_grabbed_item()
			else:
				EventBus.select_item.emit(null)

func _physics_process(_delta: float) -> void:
# Stop grabbing if click released early
	if Input.is_action_just_released("click"):
		if !grab_timer.is_stopped():
			print("InventoryManager: Aborting grab")
			grab_timer.stop()
			pending_grab_slot_data = null
			pending_grab_slot_ui = null
			EventBus.update_grabbed_slot.emit(null)
	
		if !grabbed_slot_ui.visible:
			return
		grabbed_slot_ui.position = inv_ui.get_global_mouse_position()

func _set_external_inventory(inv_data: InventoryData):
	print("InventoryManager: setting external inv")
	external_inventory_data = inv_data
	EventBus.external_inventory_set.emit(inv_data)

## -- ADDING ITEMS

func _add_item_to_inventory(inv: InventoryData, item: InventoryItemData, qty: int):
	var remaining = qty
	print("InventoryManager: _add_item_to_inventory: attempting to add %s %s to inv %s" % [str(qty), item.name, inv])
		## Attempt to merge existing slots if stackable
	if item.stackable:
		for slot in inv.slot_datas:
			if slot and slot.item_data and slot.item_data.id == item.id:
				var space = item.max_stack_size - slot.quantity
				if space > 0:
				
					var fill = min(remaining, space)
					slot.quantity += fill
					remaining -= fill
					EventBus.inventory_item_updated.emit(slot) # Notify UI
					print("InventoryManager: _add_item_to_inventory: merged %s %s into existing slot in inv %s" % [str(fill), item.name, inv])
			if remaining <= 0:
				print("InventoryManager: _add_item_to_inventory: fully merged with an existing slot")
				return 0
		## --- Attempt to fill empty slots
	if remaining > 0:
		for i in range(inv.slot_datas.size()):
			if inv.slot_datas[i] == null:
				var new_slot = InventorySlotData.new()
				new_slot.item_data = item
				new_slot.quantity = min(remaining, item.max_stack_size)
				inv.slot_datas[i] = new_slot
				remaining -= new_slot.quantity
				EventBus.inventory_item_updated.emit(new_slot) # Notify UI
			if remaining <= 0: return 0
	return remaining


## -- REMOVING ITEMS

func _remove_item_from_inventory(item_data: InventoryItemData, qty_to_remove: int, preferred_slot: InventorySlotData = null):
	print("InventoryManager: attempting to _remove_item_from_inventory...")
	var remaining = qty_to_remove
	
	# If a preferred slot was provided, take from that first
	if preferred_slot and preferred_slot.item_data == item_data:
		print("InventoryManager: _remove_item_from_inventory: preferred slot found, attempting to take from it...")
		remaining = _take_from_slot(preferred_slot, remaining)
	
	# If we still need to take more, look for other matching slots
	if remaining > 0:
		for slot in pockets_inventory_data.slot_datas:
			if slot and slot.item_data == item_data:
				print("InventoryManager: _remove_item_from_inventory: non-specific match found, attempting to take from it...")
				remaining = _take_from_slot(slot, remaining)
				if remaining <= 0: break
			
	
	EventBus.select_item.emit(null)

# Handles the moth of reducing slot quantities and clearing out empty ones
func _take_from_slot(slot: InventorySlotData, amount_needed: int) -> int:
	print("InventoryManager: _take_from_slot: attempting to take %s from %s" % [str(amount_needed), slot])
	var can_take = min(slot.quantity, amount_needed)
	slot.quantity -= can_take
	var still_needed = amount_needed - can_take
	
	# Update whatever inventory if we null out a slot
	if slot.quantity <= 0:
		_nullify_slot_in_data(slot)
	else:
		# Otherwise, update the slot
		EventBus.inventory_item_updated.emit(slot)
	print("InventoryManager: _take_from_slot: took %s from %s, still need to take %s" % [str(amount_needed), slot, str(still_needed)])
	return still_needed

func _nullify_slot_in_data(slot: InventorySlotData):
	var target_inv: InventoryData = null
	if pockets_inventory_data.slot_datas.has(slot):
		print("InventoryManager: _nullify_slot_in_data: attempting to nullify %s in pockets inventory" % slot)
		target_inv = pockets_inventory_data
	elif external_inventory_data and external_inventory_data.slot_datas.has(slot):
		print("InventoryManager: _nullify_slot_in_data: attempting to nullify %s in external inventory" % slot)
		target_inv = external_inventory_data
	
	if target_inv:
		var idx = target_inv.slot_datas.find(slot)
		target_inv.slot_datas[idx] = null
	
		EventBus.inventory_item_updated.emit(slot)

## Slot Grabbing
func _start_grabbing_slot(slot: PanelContainer, slot_data: InventorySlotData):
	# START GRAB PROCESS
	print("InventoryManager: Starting to grab a slot with _start_grabbing_slot()")
	pending_grab_slot_data = slot_data
	pending_grab_slot_ui = slot
	grab_timer.start()

func _handle_drop_or_merge(inv: InventoryData, slot_ui: PanelContainer, target_slot_data: InventorySlotData):
	var target_index = slot_ui.get_index()
	# Confirms item exists and is stackable
	if target_slot_data and target_slot_data.item_data and target_slot_data.item_data == grabbed_slot_data.item_data and target_slot_data.item_data.stackable:
		# Check for mergability
		var space_left = target_slot_data.item_data.max_stack_size - target_slot_data.quantity
		if space_left > 0:
			var amount_to_move = min(grabbed_slot_data.quantity, space_left)
			target_slot_data.quantity += amount_to_move
			grabbed_slot_data.quantity -= amount_to_move
			# Clear grabbed slot if empty
			if grabbed_slot_data.quantity <= 0:
				grabbed_slot_data = null
			
			# Update UI
			EventBus.inventory_item_updated.emit(target_slot_data)
			EventBus.update_grabbed_slot.emit(grabbed_slot_data)
			return
	
		## SWAP / DROP LOGIC
	if target_slot_data:
		var source_idx = source_inventory.slot_datas.find(null) # finds the empty slot we left behind
		if source_idx != -1:
			source_inventory.slot_datas[source_idx] = target_slot_data
			# Tell the OG inventory that its baby is gone
			EventBus.inventory_item_updated.emit(target_slot_data)
		
	inv.slot_datas[target_index] = grabbed_slot_data
	slot_ui.set_slot_data(grabbed_slot_data)
	
	grabbed_slot_data = null
	source_inventory = null
	EventBus.update_grabbed_slot.emit(null)
	
func _on_grab_timer_timeout() -> void:
	if pending_grab_slot_data:
		print("InventoryManager: Grab Timer Timeout")
		grabbed_slot_data = pending_grab_slot_data
		source_inventory = pending_grab_slot_ui.parent_inventory
		
		var idx = source_inventory.slot_datas.find(grabbed_slot_data)
		if idx != -1:
			source_inventory.slot_datas[idx] = null
		
		
		pending_grab_slot_ui.clear_slot_data(grabbed_slot_data) # Clears the original slot
		EventBus.update_grabbed_slot.emit(grabbed_slot_data) # Sets it to the grabbed slot ui
		EventBus.select_item.emit(null)
		# Remove temp data
		pending_grab_slot_data = null
		pending_grab_slot_ui = null

func _split_item_stack(new_grab_data: InventorySlotData):
	print("InventoryManager: splitting item stack")
	grabbed_slot_data = new_grab_data
	EventBus.update_grabbed_slot.emit(new_grab_data)
	EventBus.select_item.emit(null)

func _discard_grabbed_item():
	print("Discarding %s into the world" % grabbed_slot_data.item_data.name)
	
	# This signal will be used in the 3D game to spawn a 3D pickup of the discarded item
	EventBus.item_discarded.emit(grabbed_slot_data, inv_ui.get_global_mouse_position())
	
	# Clean up manager state
	grabbed_slot_data = null
	source_inventory = null
	EventBus.update_grabbed_slot.emit(null)

### ---- Transfering items

func _handle_quick_move(source_inv: InventoryData, slot_data: InventorySlotData):
	# Determine destination
	var destination_inv = external_inventory_data if source_inv == pockets_inventory_data else pockets_inventory_data
	
	if not destination_inv:
		print("InventoryManager: _handle_quick_move: no destination to quick transfer to")
		return
	
	# Determine how many we are moving
	var starting_qty = slot_data.quantity
	
	# Try to transfer item
	var remaining = _add_item_to_inventory(destination_inv, slot_data.item_data, starting_qty)
	
	# Update source slot
	if remaining <= 0:
		_nullify_slot_in_data(slot_data)
	else:
		slot_data.quantity = remaining
	EventBus.inventory_item_updated.emit(slot_data)
	print("InventoryManager: _handle_quick_move: finished running")
