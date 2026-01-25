extends PanelContainer
class_name SlotUI

var parent_inventory: InventoryData
@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

@onready var selected_panel: Panel = %SelectedPanel


func _ready() -> void:
	#EventBus.splitting_item_stack.connect(_stack_split)
	EventBus.inventory_item_updated.connect(_on_item_updated)

func set_slot_data(new_slot_data: InventorySlotData):
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
	#EventBus.inventory_item_updated.emit(slot_data) # For use by other nodes if needed, locally the same as running _on_item_updated()

func _on_item_updated(updated_slot_data: InventorySlotData):
	# Only updates if slot is actually changed
	if updated_slot_data == slot_data:
		if slot_data == null or slot_data.item_data == null:
			clear_visuals()
		else:
			set_slot_data(updated_slot_data)
			_update_visuals()

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
	selected_panel.hide()
	item_texture.hide()
	quantity.hide()
	tooltip_text = ""

func clear_slot_data(_slot: InventorySlotData):
	item_texture.texture = null
	slot_data = null
	clear_visuals()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "click")
			print("Slot clicked")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.inventory_interacted.emit(parent_inventory, self, slot_data, "r_click")
			print("Slot r-clicked")
