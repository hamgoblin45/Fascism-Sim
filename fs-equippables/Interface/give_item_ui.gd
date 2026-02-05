extends PanelContainer

@export var slot_data: InventorySlotData

@onready var item_texture: TextureRect = %ItemTexture
@onready var quantity: Label = %Quantity




func _give_item(new_slot_data: InventorySlotData):
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
