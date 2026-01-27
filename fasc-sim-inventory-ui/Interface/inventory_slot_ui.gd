extends PanelContainer
class_name SlotUI

var parent_inventory: InventoryData
@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

@onready var selected_panel: Panel = %SelectedPanel


func _ready() -> void:
	EventBus.inventory_item_updated.connect(_on_item_updated)
	EventBus.select_item.connect(_select_item)
	#Hover effect
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func set_slot_data(new_slot_data: InventorySlotData):
	slot_data = new_slot_data
	if !slot_data or !slot_data.item_data:
		print("InventorySlotUI: set_slot_data: setting empty slot")
		return
	
	print("InventorySlotUI: set_slot_data: DATA: %s, ITEM: %s" % [slot_data, slot_data.item_data.name])
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	tooltip_text = slot_data.item_data.name
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()

func _select_item(data: InventorySlotData):
	# Show if panel being selected, hide if not
	#print("InventorySlotUI: select_item: selecting %s" % data)
	selected_panel.visible = (data == slot_data and data != null)
	

func _on_item_updated(inv_data: InventoryData, index: int):
	# Only updates if slot is actually changed
	if inv_data == parent_inventory and index == get_index():
		selected_panel.hide()
		
		var new_data = parent_inventory.slot_datas[index]
		if new_data == null or new_data.quantity <= 0:
			clear_slot_data(null)
		else:
			print("InventorySlotUI: _on_item_updated running...")
			set_slot_data(new_data)
			_update_visuals()

func _update_visuals():
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()

func _on_mouse_entered():
	# Shows a subtle highlight on hover
	if !selected_panel.visible:
		modulate = Color(1.2, 1.2, 1.2) # Slightly brighten

func _on_mouse_exited():
	modulate = Color(1,1,1) # Reset to normal

## -- Remove from slot
func clear_visuals():
	selected_panel.hide()
	item_texture.hide()
	quantity.hide()
	tooltip_text = ""

func clear_slot_data(_slot: InventorySlotData):
	print("InventorySlotUI: clearing slot data")
	slot_data = null
	item_texture.texture = null
	clear_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# Shift click
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SHIFT):
				EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "shift_click")
				print("InventorySlotUI: Shift Slot clicked")
			else:
				EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "click")
				print("InventorySlotUI: Slot clicked")
			return
		
			
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "r_click")
			print("InventorySlotUI: Slot right-clicked")
