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
@onready var pocket_slot_container: GridContainer = %PocketSlotContainer
@onready var external_inventory: PanelContainer = %ExternalInventory
@onready var shop_ui: PanelContainer = %ShopUI
@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI
@onready var grab_timer: Timer = %GrabTimer




func _ready() -> void:
	EventBus.inventory_interacted.connect(_on_inventory_interact)
	EventBus.adding_item.connect(_add_item_to_inventory)
	EventBus.removing_item.connect(_remove_item_from_inventory)
	#EventBus.selling_item.connect(_sell_item)
	#EventBus.using_item.connect(_use_item)
	EventBus.setting_external_inventory.connect(_set_external_inventory)
	
	# Sets player inventory
	EventBus.pockets_inventory_set.emit(pockets_inventory_data)
	# If bags added later, emit setup here



## -- INVENTORY INTERACTION
func _on_inventory_interact(inv: InventoryData, slot: PanelContainer, slot_data: InventorySlotData, type: String):
	#match inv:
		#pockets_inventory_data:
			match type:
				"click":
					print("Click on %s in %s by inventoryUI" % [slot, inv])
					if grabbed_slot_data:
						_handle_drop_or_merge(slot, slot_data)
					else:
						EventBus.select_item.emit(inv, slot_data)
						if slot_data and slot_data.item_data:
							if Input.is_action_pressed("shift"):
								EventBus.open_split_stack_ui.emit(slot_data)
								return
							
							
							# START GRAB PROCESS
							_start_grabbing_slot(inv, slot, slot_data)

				"r_click":
					print("R-Click on %s in Inv %s received by inventoryUI" % [slot, inv])
					if grabbed_slot_data:
						if slot_data and slot_data.item_data:
							print("Right Clicked %s" % slot_data.item_data.name)
							
							if grabbed_slot_data != slot_data:
								print("Trying to merge grabbed slot with existing slot")
								if grabbed_slot_data.item_data == slot_data.item_data and slot_data.item_data.stackable:
									slot_data.quantity += 1
									grabbed_slot_data.quantity -= 1
									EventBus.grabbed_item_slot.emit(slot_data)
									slot.set_slot_data(slot_data)
									
						else:
							print("Trying to drop a single item into an empty slot, creating slot data")
							slot_data = InventorySlotData.new()
							slot_data.item_data = grabbed_slot_data.item_data
							slot_data.quantity = 1
							grabbed_slot_data.quantity -= 1
									
								#elif grabbed_slot_data.item_data.stackable
						if grabbed_slot_data.quantity <= 0:
							print("Grabbed slot empty")
							grabbed_slot_data = null
						
						slot.set_slot_data(slot_data)
						inv_ui._set_grabbed_slot_ui()
					else:
						if slot_data and slot_data.item_data:
							EventBus.open_item_context_menu.emit(slot_data)
						#item_context_ui.set_context_menu(slot_data)

func _physics_process(_delta: float) -> void:
# Stop grabbing if click released early
	if Input.is_action_just_released("click"):
		if !grab_timer.is_stopped():
			grab_timer.stop()
			pending_grab_slot_data = null
			pending_grab_slot_ui = null

func _set_external_inventory(inv_data: InventoryData):
	external_inventory_data = inv_data

## -- ADDING ITEMS

func _add_item_to_inventory(item_to_add: InventoryItemData, qty_to_add: int):
	if can_inventory_fit(item_to_add, qty_to_add):
		print("Adding item %s to inventory" % item_to_add.name)
		
		## Attempt to merge existing slots if stackable
		if item_to_add.stackable:
			for slot_ui in pocket_slot_container.get_children():
				var slot = slot_ui.slot_data
				if slot and slot.item_data and slot.item_data.id == item_to_add.id:
					var space_in_stack = item_to_add.max_stack_size - slot.quantity
					if space_in_stack > 0:
						var qty_to_fill = min(qty_to_add, space_in_stack)
						slot.quantity += qty_to_fill
						qty_to_add -= qty_to_fill
						slot_ui.set_slot_data(slot)
					print("Able to merge new item with an existing slot")
					
				if qty_to_add <= 0:
					break
		
		if qty_to_add > 0:
			for slot_ui in pocket_slot_container.get_children():
				if !slot_ui.slot_data or !slot_ui.slot_data.item_data:
					var new_slot = InventorySlotData.new()
					new_slot.item_data = item_to_add
					
					## How much goes into new slot
					var current_batch = qty_to_add
					if item_to_add.stackable:
						current_batch = min(qty_to_add, item_to_add.max_stack_size) #As much as can fit if stackable
					else:
						current_batch = 1 # 1 for nonstackable
					new_slot.quantity = current_batch
					qty_to_add -= current_batch
					slot_ui.set_slot_data(new_slot)
				if qty_to_add <= 0:
					break
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

func _remove_item_from_inventory(slot_data: InventorySlotData):
	print("Removing item %s from inventory" % slot_data.item_data.name)
	var qty_to_remove = slot_data.quantity
	var pocket_slots = pocket_slot_container.get_children()
	for i in range(pocket_slots.size() -1, -1, -1):
		var slot_ui = pocket_slots[i]
		var slot = slot_ui.slot_data
		
		if slot and slot.item_data and slot.item_data.id == slot_data.item_data.id:
			if slot.quantity > qty_to_remove:
				#Stack has more than amount requested to remove
				slot.quantity -= qty_to_remove
				qty_to_remove = 0
				slot_ui.set_slot_data(slot)
			else:
				# Stack is <= to amount requested to remove
				qty_to_remove -= slot.quantity
				slot_ui.clear_slot_data(slot)
			
			if qty_to_remove <= 0:
				print("Could only remove some items, %s still missing" % qty_to_remove)


## Slot Grabbing

func _start_grabbing_slot(inv: InventoryData, slot: PanelContainer, slot_data: InventorySlotData):
	# START GRAB PROCESS
	
	pending_grab_slot_data = slot_data
	pending_grab_slot_ui = slot
	grab_timer.start()

func _handle_drop_or_merge(slot, slot_data):
	if slot_data and slot_data.item_data and slot_data.item_data.id == grabbed_slot_data.item_data.id and slot_data.item_data.stackable:
		# Check for mergability
		var space_left = slot_data.item_data.max_stack_size - slot_data.quantity
		if space_left > 0:
			var amount_to_move = min(grabbed_slot_data.quantity, space_left)
			slot_data.quantity += amount_to_move
			grabbed_slot_data.quantity -= amount_to_move
			
			slot.set_slot_data(slot_data)
			
			EventBus.grabbed_item_slot.emit(slot_data)
			print("Item merge success")
			return
	else:
		## SWAP / DROP LOGIC
		var temp_data = slot_data
		slot.set_slot_data(grabbed_slot_data)
		
		if temp_data and temp_data.item_data:
			grabbed_slot_data = temp_data
		
		EventBus.grabbed_item_slot.emit(slot_data)

func _on_grab_timer_timeout() -> void: # Done
	if pending_grab_slot_data:
		grabbed_slot_data = pending_grab_slot_data
		pending_grab_slot_ui.clear_slot_data(pending_grab_slot_data) # Clears the original slot
		EventBus.grabbed_item_slot.emit(pending_grab_slot_data) # Sets it to the grabbed slot ui
		# Remove temp data
		pending_grab_slot_data = null
		pending_grab_slot_ui = null
