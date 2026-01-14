extends Control

@export var inventory_data: InventoryData # Player's pockets
var external_inventory_data: InventoryData # Containers

var grabbed_slot_data: InventorySlotData

const INVENTORY_SLOT = preload("uid://d3yl41a7rncgb")

@onready var player_inventory_ui: PanelContainer = %PlayerInventoryUI
@onready var pocket_slot_container: GridContainer = %PocketSlotContainer

@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI

@onready var grabbed_item_texture: TextureRect = %GrabbedItemTexture
@onready var grabbed_quantity: Label = %GrabbedQuantity
@onready var grab_timer: Timer = %GrabTimer

@onready var item_context_ui: PanelContainer = %ItemContextUI

@onready var external_inventory: PanelContainer = %ExternalInventory
@onready var external_slot_container: GridContainer = %ExternalSlotContainer

@onready var give_item_ui: PanelContainer = %GiveItemUI
@onready var give_item_slot: PanelContainer = %GiveItemSlot


func _ready() -> void:
	EventBus.inventory_interacted.connect(_on_inventory_interact)
	EventBus.splitting_item_stack.connect(_on_slot_split)
	EventBus.setting_external_inventory.connect(_set_external_inventory)
	EventBus.adding_item_to_inventory.connect(_add_item_to_inventory)
	EventBus.removing_item_from_inventory.connect(_remove_item_from_inventory)
	_set_player_inventory()


func _set_player_inventory():
	for child in pocket_slot_container.get_children():
		child.queue_free()
	for slot in inventory_data.slot_datas:
		var slot_ui = INVENTORY_SLOT.instantiate()
		pocket_slot_container.add_child(slot_ui)
		slot_ui.set_slot_data(slot)

func _on_inventory_interact(slot: PanelContainer, slot_data: InventorySlotData, type: String):
	match type:
		"click":
			print("Click from %s received by inventoryUI" % slot)
			if grabbed_slot_data:
				if grabbed_slot_data.item_data.id and slot_data.item_data.id and slot_data.item_data.stackable:
					# Check for mergability
					var space_left = slot_data.item_data.max_stack_size - slot_data.quantity
					if space_left > 0:
						var amount_to_move = min(grabbed_slot_data.quantity, space_left)
						slot_data.quantity += amount_to_move
						grabbed_slot_data.quantity -= amount_to_move
						
						if grabbed_slot_data.quantity <= 0:
							_clear_grabbed_slot()
						else:
							_set_grabbed_slot()
						
						slot.set_slot_data(slot_data)
						print("Item merge success")
						return
					
					#if grabbed_slot_data != slot_data:
						#print("Trying to merge grabbed slot with existing slot")
						#if grabbed_slot_data.item_data == slot_data.item_data and slot_data.item_data.stackable:
							#slot_data.quantity += grabbed_slot_data.quantity
							#_clear_grabbed_slot()
							#
						#else:
							#var sd = grabbed_slot_data
							#grabbed_slot_data = slot_data
							#slot_data = sd
							#_set_grabbed_slot()
						#slot.set_slot_data(slot_data)
					#
				#else:
					#slot.set_slot_data(grabbed_slot_data)
					#_clear_grabbed_slot()
			
			else:
				if Input.is_action_pressed("shift"):
					EventBus.open_split_stack_ui.emit(slot_data)
					return
				grabbed_slot_data = slot_data
				grab_timer.start()
		"r_click":
			print("Right Click from %s received by inventoryUI" % slot)
			if grabbed_slot_data:
				if slot_data and slot_data.item_data:
					print("Right Clicked %s" % slot_data.item_data.name)
					
					if grabbed_slot_data != slot_data:
						print("Trying to merge grabbed slot with existing slot")
						if grabbed_slot_data.item_data == slot_data.item_data and slot_data.item_data.stackable:
							slot_data.quantity += 1
							grabbed_slot_data.quantity -= 1
							
				else:
					print("Trying to drop a single item into an empty slot, creating slot data")
					slot_data = InventorySlotData.new()
					slot_data.item_data = grabbed_slot_data.item_data
					slot_data.quantity = 1
					grabbed_slot_data.quantity -= 1
							
						#elif grabbed_slot_data.item_data.stackable
				if grabbed_slot_data.quantity <= 0:
					print("Grabbed slot empty")
					_clear_grabbed_slot()
				
				slot.set_slot_data(slot_data)
				_set_grabbed_slot()
			else:
				if slot_data and slot_data.item_data:
					EventBus.open_item_context_menu.emit(slot_data)
				#item_context_ui.set_context_menu(slot_data)

func _physics_process(_delta: float) -> void:
	if grabbed_slot_ui.visible:
		grabbed_slot_ui.position = get_local_mouse_position()
	# Stop grabbing if click released early
	if Input.is_action_just_released("click"):
		print("click released")
		if grabbed_slot_data and not grab_timer.is_stopped():
			grabbed_slot_data = null
			grab_timer.stop()
			print("grab aborted")

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
		for slot in inventory_data.slot_datas: # check data directly
			if slot and slot.item_data and slot.item_data.id == item_to_add.id:
				remaining_needed -= (item_to_add.max_stack_size - slot.quantity)
				if remaining_needed <= 0: return true
	# Check empty slots
	var empty_slots = 0
	for slot in inventory_data.slot_datas:
		if !slot or !slot.item_data:
			empty_slots += 1
	
	if item_to_add.stackable:
		# Check how many stacks we can fit
		var space_in_slot = empty_slots * item_to_add.max_stack_size
		return remaining_needed <= space_in_slot
	else:
		# Handle non-stackables
		return remaining_needed <= empty_slots

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

func _set_grabbed_slot():
	if !grabbed_slot_data or !grabbed_slot_data.item_data:
		print("Trying to set grabbed slot in InventoryUI but has no slot and/or item_data")
		return
	grabbed_slot_ui.position = get_local_mouse_position()
	grabbed_slot_ui.show()
	grabbed_item_texture.texture = grabbed_slot_data.item_data.texture
	if grabbed_slot_data.quantity > 1 and grabbed_slot_data.item_data.stackable:
		grabbed_quantity.show()
		grabbed_quantity.text = str(grabbed_slot_data.quantity)
	else:
		grabbed_quantity.hide()
	
	EventBus.removing_item_from_inventory.emit(grabbed_slot_data)

func _clear_grabbed_slot():
	grabbed_slot_data = null
	grabbed_slot_ui.hide()

func _on_slot_split(slot: InventorySlotData, _orig_slot_data: InventorySlotData):
	grabbed_slot_data = slot
	_set_grabbed_slot()

func _on_grab_timer_timeout() -> void:
	_set_grabbed_slot()

func _set_external_inventory(inv_data: InventoryData):
	external_inventory_data = inv_data
	for slot in external_slot_container.get_children():
		slot.queue_free()
	if !inv_data:
		external_inventory.hide()
		
	else:
		external_inventory.show()
		for slot in external_inventory_data.slot_datas:
			var slot_ui = INVENTORY_SLOT.instantiate()
			external_slot_container.add_child(slot_ui)
			slot_ui.set_slot_data(slot)

func _on_give_item_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if grabbed_slot_data:
			if event.button_index == MOUSE_BUTTON_LEFT:
				print("Giving full grabbed stack")
				EventBus.giving_item.emit(grabbed_slot_data)
				_clear_grabbed_slot()
			if event.button_index == MOUSE_BUTTON_RIGHT:
				var single_stack = InventorySlotData.new()
				single_stack.item_data = grabbed_slot_data.item_data
				single_stack.quantity = 1
				print("Giving a single of grabbed stack")
				EventBus.giving_item.emit(single_stack)
				grabbed_slot_data.quantity -= 1
							
						#elif grabbed_slot_data.item_data.stackable
				if grabbed_slot_data.quantity <= 0:
					_clear_grabbed_slot()
			_set_grabbed_slot()
