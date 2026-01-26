extends Resource
class_name InventorySlotData

@export var item_data: InventoryItemData
@export var quantity: int = 1

func _is_empty() -> bool:
	return item_data == null or quantity <= 0
