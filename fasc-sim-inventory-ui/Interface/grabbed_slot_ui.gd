extends PanelContainer

@onready var grabbed_item_texture: TextureRect = %GrabbedItemTexture
@onready var grabbed_quantity: Label = %GrabbedQuantity


func _ready() -> void:
	EventBus.update_grabbed_slot.connect(_update_grabbed_slot)

func _physics_process(_delta: float) -> void: # Not working, not sure why
	if visible:
		position = get_parent().get_local_mouse_position()

func _update_grabbed_slot(slot: InventorySlotData):
	print("Setting grabbed slot in GrabbedSlotUI")
	
	if slot == null:
		_clear_grabbed_slot()
		return
	
	show()
	grabbed_item_texture.texture = slot.item_data.texture
	
	if slot.quantity > 1:
		grabbed_quantity.text = str(slot.quantity)
		grabbed_quantity.show()
	
	position = get_parent().get_local_mouse_position()

func _clear_grabbed_slot():
	print("Clearing grabbed slot in GrabbedSlotUI")
	hide()
	grabbed_quantity.hide()
	grabbed_item_texture.texture = null
