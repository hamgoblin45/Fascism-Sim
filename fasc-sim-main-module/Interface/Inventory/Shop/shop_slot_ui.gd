extends PanelContainer

var parent_inventory: InventoryData

@export var slot_data: SlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity
@onready var selected_panel: Panel = %SelectedPanel


func set_slot_data(new_slot_data: SlotData):
	slot_data = new_slot_data
	if !slot_data or !slot_data.item_data:
		print("Setting slot in InventorySlotUI, has no slot and/or item_data")
		return
	
	print("Set_Slot_Data run in inv_slot_ui. New slot: %s" % slot_data)
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	tooltip_text = slot_data.item_data.name
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()
	
	var qty = slot_data.quantity
	if not slot_data.item_data.stackable:
		qty = 1
	EventBus.inventory_item_updated.emit(parent_inventory, qty)

func _update_visuals():
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()

## -- Remove from slot
func clear_visuals():
	item_texture.hide()
	quantity.hide()
	tooltip_text = ""

func clear_slot_data(slot: SlotData):
	if slot and slot != slot_data: return # Verify this slot is the right one
	
	print("Clear slot run on InventorySlotUI. Slot: %s" % slot)
	item_texture.texture = null
	slot_data = null
	clear_visuals()
	
	EventBus.inventory_item_updated.emit(null)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "click")
			#print("Shop UI slot clicked")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "r_click")
