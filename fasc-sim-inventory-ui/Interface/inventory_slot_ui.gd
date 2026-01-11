extends PanelContainer

@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity


func _set_slot_data(new_slot_data: InventorySlotData):
	slot_data = new_slot_data
	if !slot_data.item_data:
		return
	
	item_texture.show()
	item_texture.texture = slot_data.item_data.texture
	if slot_data.quantity > 1:
		quantity.show()
		quantity.text = str(slot_data.quantity)
