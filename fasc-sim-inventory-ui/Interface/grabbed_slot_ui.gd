extends PanelContainer

var slot_data: InventorySlotData

@onready var grabbed_item_texture: TextureRect = %GrabbedItemTexture
@onready var grabbed_quantity: Label = %GrabbedQuantity


func _ready() -> void:
	EventBus.grabbed_item_slot.connect(_set_grabbed_slot)

func _physics_process(_delta: float) -> void:
	if !slot_data or !visible:
		return
	position = get_local_mouse_position()

func _set_grabbed_slot(slot: InventorySlotData):
	slot_data = slot
	
	if slot == null:
		_clear_grabbed_slot()
		return
	
	show()
	grabbed_item_texture.texture = slot.item_data.texture
	
	if slot.quantity > 1:
		grabbed_quantity.text = str(slot.quantity)
		grabbed_quantity.show()
	
	position = get_local_mouse_position()

func _clear_grabbed_slot():
	hide()
	grabbed_quantity.hide()
	grabbed_item_texture.texture = null
