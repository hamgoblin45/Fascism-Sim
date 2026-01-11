extends PanelContainer

@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity

func _ready() -> void:
	EventBus.removing_item_from_inventory.connect(_clear_slot_data)

func _set_slot_data(new_slot_data: InventorySlotData):
	slot_data = new_slot_data
	if !slot_data.item_data:
		return
	
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
	EventBus.inventory_item_updated.emit(slot_data)

func _clear_slot_data(slot: InventorySlotData):
	if slot.item_data and slot_data.item_data and slot.item_data == slot_data.item_data:
		slot_data = null
		item_texture.hide()
		quantity.hide()
		EventBus.inventory_item_updated.emit(slot_data)

func _change_quantity(value: int):
	slot_data.quantity += value
	if slot_data.quantity > 1 and slot_data.item_data.stackable:
		quantity.show()
		quantity.text = str(slot_data.quantity)
		EventBus.inventory_item_updated.emit(slot_data)
	elif slot_data.quantity <= 0:
		_clear_slot_data(slot_data)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		#print("Inv slot clicked")
		if event.button_index == MOUSE_BUTTON_LEFT:
			#if Input.is_action_pressed("")
			print("left click")
			EventBus.inventory_interacted.emit(slot_data, "click")
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print("right click")
			EventBus.inventory_interacted.emit(slot_data, "r_click")
