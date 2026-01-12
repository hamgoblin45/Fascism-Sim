extends PanelContainer

@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

func _ready() -> void:
	EventBus.removing_item_from_inventory.connect(_clear_slot_data)
	EventBus.splitting_item_stack.connect(_stack_split)
	

func set_slot_data(new_slot_data: InventorySlotData):
	slot_data = new_slot_data
	if !slot_data or !slot_data.item_data:
		print("Setting slot in InventorySlotUI, has no slot and/or item_data")
		return
	
	print("Set_Slot_Data run in inv_slot_ui. New slot: %s" % slot_data)
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	else:
		quantity.hide()
	EventBus.inventory_item_updated.emit(slot_data)

func _clear_slot_data(slot: InventorySlotData):
	if !slot or !slot_data: return
	if slot.item_data and slot_data.item_data and slot == slot_data:
		print("Clear slot run on InventorySlotUI. Slot: %s" % slot)
		slot_data = null
		item_texture.hide()
		quantity.hide()
		EventBus.inventory_item_updated.emit(slot_data)

func _stack_split(result_slot: InventorySlotData, orig_slot: InventorySlotData):
	if orig_slot != slot_data: return
	print("Change quantity called on inv_slot_ui. New slot: %s, Orig Slot: %s" % [result_slot, orig_slot])
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	elif slot_data.quantity <= 0:
		_clear_slot_data(slot_data)
	set_slot_data(orig_slot)
	EventBus.inventory_item_updated.emit(slot_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		#print("Inv slot clicked")
		if event.button_index == MOUSE_BUTTON_LEFT:
			#if Input.is_action_pressed("")
			#print("left click")
			EventBus.inventory_interacted.emit(self, slot_data, "click")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			#print("right click")
			EventBus.inventory_interacted.emit(self, slot_data, "r_click")
