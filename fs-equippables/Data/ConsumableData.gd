extends InventoryItemData
class_name ConsumableData

@export var remaining: float = 1.0 # 0.0 is empty, 1.0 is full
@export var effects: Dictionary = {
	# Stat effected is the key (ie, hp, energy, hunger, etc) and value
}
