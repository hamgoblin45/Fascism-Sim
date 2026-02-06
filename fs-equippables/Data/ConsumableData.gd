extends InventoryItemData
class_name ConsumableData

@export var effects: Dictionary = {
	# Stat effected is the key (ie, hp, energy, hunger, etc) and value
	"hp": 0.0,
	"energy": 0.0,
	"hunger": 0.0,
	"stress": 0.0
}
