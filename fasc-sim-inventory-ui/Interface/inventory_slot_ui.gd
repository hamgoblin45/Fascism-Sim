extends PanelContainer

@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

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
	EventBus.inventory_item_updated.emit(slot_data)

func _on_item_updated(updated_slot_data: InventorySlotData):
	# Only updates if slot is actually changed
	if updated_slot_data == slot_data:
		if slot_data == null or slot_data.item_data == null:
			clear_visuals()
		else:
			_update_visuals()

func _update_visuals():
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()

func clear_visuals():
	item_texture.hide()
	quantity.hide()
	tooltip_text = ""


func clear_slot_data(slot: InventorySlotData):
	if slot and slot != slot_data: return # Verify this slot is the right one
	
	print("Clear slot run on InventorySlotUI. Slot: %s" % slot)
	item_texture.texture = null
	slot_data = null
	clear_visuals()
	
	EventBus.inventory_item_updated.emit(null)


func _stack_split(result_slot: InventorySlotData, amount: int):
	#print("Change quantity called on inv_slot_ui. New slot: %s, Orig Slot: %s" % [result_slot, orig_slot])
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	elif slot_data.quantity <= 0:
		clear_slot_data(slot_data)
	EventBus.inventory_item_updated.emit(slot_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			EventBus.inventory_interacted.emit(self, slot_data, "click")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			EventBus.inventory_interacted.emit(self, slot_data, "r_click")
