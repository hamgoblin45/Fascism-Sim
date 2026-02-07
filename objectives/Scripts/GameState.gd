extends Node

var inventory: InventoryData = InventoryData.new()

## -- Regime / World
var suspicion: float = 0.0:
	set(value): suspicion = clamp(value, 0, 100)
var resistance: float = 0.0:
	set(value): resistance = clamp(value, 0, 100)

# - Memory
var world_flags: Dictionary = {
	# This is where you will keep keys like "first_warning_received" or "doug_arrested" with bool values
	# Can just use something like "set GameState.world_flags.neighbor_arrested = true" in Dialogic
}

var objectives: Array[ObjectiveData]

var flags = {}


func set_flag(id: String, value: bool):
	flags[id] = value
	EventBus.world_changed.emit(id, value) # NPCs and other scenes can listen to this and change accordingly

func get_flag(id: String) -> bool:
	return flags.get(id, false)
