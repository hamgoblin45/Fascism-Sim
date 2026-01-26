extends Node
# Holds all the inter-connected inventory logic

@export var pockets_inventory_data: InventoryData
@export var external_inventory_data: InventoryData # These should be set by signals but using export for testing
@export var shop_inventory_data: InventoryData # These should be set by signals but using export for testing

var grabbed_slot_data: InventorySlotData
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
		"click":
			print("Click on %s in %s by inventoryUI" % [slot_ui, inv])
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
			print("R-Click on %s in Inv %s received by inventoryUI" % [slot_data, inv])
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

func _physics_process(_delta: float) -> void:
# Stop grabbing if click released early
	if Input.is_action_just_released("click"):
		if !grab_timer.is_stopped():
			print("Stopping grab timer in InventoryManager")
			grab_timer.stop()
			pending_grab_slot_data = null
			pending_grab_slot_ui = null
			EventBus.update_grabbed_slot.emit(null)
	
		if !grabbed_slot_ui.visible:
			return
		grabbed_slot_ui.position = inv_ui.get_global_mouse_position()

func _set_external_inventory(inv_data: InventoryData):
	external_inventory_data = inv_data
	EventBus.external_inventory_set.emit(inv_data)

## -- ADDING ITEMS

func _add_item_to_inventory(item_to_add: InventoryItemData, qty_to_add: int):
	var remaining = qty_to_add

		## Attempt to merge existing slots if stackable
	if item_to_add.stackable:
		for slot in pockets_inventory_data.slot_datas:
			if slot and slot.item_data and slot.item_data.id == item_to_add.id:
				var space = item_to_add.max_stack_size - slot.quantity
				var fill = min(remaining, space)
				slot.quantity += fill
				remaining -= fill
				EventBus.inventory_item_updated.emit(slot) # Notify UI
			if remaining <= 0: break
			
	if remaining > 0:
		for i in range(pockets_inventory_data.slot_datas.size()):
			if pockets_inventory_data.slot_datas[i] == null:
				var new_slot = InventorySlotData.new()
				new_slot.item_data = item_to_add
				new_slot.quantity = min(remaining, item_to_add.max_stack_size)
				pockets_inventory_data.slot_datas[i] = new_slot
				remaining -= new_slot.quantity
				EventBus.inventory_item_updated.emit(new_slot) # Notify UI
			if remaining <= 0: break
	else:
		print("Inventory full, blocking pickup")

func can_inventory_fit(item_to_add: InventoryItemData, quantity: int) -> bool:
	var remaining_needed = quantity
	#Check existing stacks
	if item_to_add.stackable:
		for slot in pockets_inventory_data.slot_datas: # check data directly
			if slot and slot.item_data and slot.item_data.id == item_to_add.id:
				remaining_needed -= (item_to_add.max_stack_size - slot.quantity)
				if remaining_needed <= 0: return true
	# Check empty slots
	var empty_slots = 0
	for slot in pockets_inventory_data.slot_datas:
		if !slot or !slot.item_data:
			empty_slots += 1
	
	if item_to_add.stackable:
		# Check how many stacks we can fit
		var space_in_slot = empty_slots * item_to_add.max_stack_size
		return remaining_needed <= space_in_slot
	else:
		# Handle non-stackables
		return remaining_needed <= empty_slots

## -- REMOVING ITEMS

func _remove_item_from_inventory(item_data: InventoryItemData, qty_to_remove: int, preferred_slot: InventorySlotData = null):
	var remaining = qty_to_remove
	
	# If a preferred slot was provided, take from that first
	if preferred_slot and preferred_slot.item_data == item_data:
		remaining = _take_from_slot(preferred_slot, remaining)
	
	# If we still need to take more, look for other matching slots
	if remaining > 0:
		for slot in pockets_inventory_data.slot_datas:
			if slot and slot.item_data == item_data:
				remaining = _take_from_slot(slot, remaining)
	
	EventBus.select_item.emit(null)

# Handles the moth of reducing slot quantities and clearing out empty ones
func _take_from_slot(slot: InventorySlotData, amount_needed: int) -> int:
	var can_take = min(slot.quantity, amount_needed)
	slot.quantity -= can_take
	var still_needed = amount_needed - can_take
	
	# Update whatever inventory if we null out a slot
	if slot.quantity <= 0:
		_nullify_slot_in_data(slot)
	else:
		# Otherwise, update the slot
		EventBus.inventory_item_updated.emit(slot)
	return still_needed

func _nullify_slot_in_data(slot: InventorySlotData):
	if pockets_inventory_data.slot_datas.has(slot):
		var idx = pockets_inventory_data.slot_datas.find(slot)
		pockets_inventory_data.slot_datas[idx] = null
	elif external_inventory_data and external_inventory_data.slot_datas.has(slot):
		var idx = external_inventory_data.slot_datas.find(slot)
		external_inventory_data.slot_datas[idx] = null
	EventBus.inventory_item_updated.emit(slot)

## Slot Grabbing

func _start_grabbing_slot(slot: PanelContainer, slot_data: InventorySlotData):
	# START GRAB PROCESS
	print("Starting to grab slot")
	pending_grab_slot_data = slot_data
	pending_grab_slot_ui = slot
	grab_timer.start()

func _handle_drop_or_merge(inv: InventoryData, slot_ui: PanelContainer, target_slot_data: InventorySlotData):
	# Confirms item exists and is stackable
	if target_slot_data and target_slot_data.item_data and target_slot_data.item_data == grabbed_slot_data.item_data:
		if target_slot_data.item_data.stackable:
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
	var index = slot_ui.get_index()
	var temp_grabbed = grabbed_slot_data
	grabbed_slot_data = target_slot_data
	inv.slot_datas[index] = temp_grabbed
	
	slot_ui.set_slot_data(temp_grabbed)
	EventBus.update_grabbed_slot.emit(grabbed_slot_data)

func _on_grab_timer_timeout() -> void:
	if pending_grab_slot_data:
		grabbed_slot_data = pending_grab_slot_data
		pending_grab_slot_ui.clear_slot_data(pending_grab_slot_data) # Clears the original slot
		EventBus.update_grabbed_slot.emit(pending_grab_slot_data) # Sets it to the grabbed slot ui
		EventBus.select_item.emit(null)
		# Remove temp data
		pending_grab_slot_data = null
		pending_grab_slot_ui = null

func _split_item_stack(new_grab_data: InventorySlotData):
	grabbed_slot_data = new_grab_data
	EventBus.update_grabbed_slot.emit(new_grab_data)
	EventBus.select_item.emit(null)
