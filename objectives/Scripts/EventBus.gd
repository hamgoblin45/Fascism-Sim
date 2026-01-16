extends Node

# For testing
signal inventory_item_updated(slot: InventorySlotData)

# Request signals (when attempting)
signal assign_objective(objective: ObjectiveData)
signal advance_objective(objective: ObjectiveData)
signal complete_objective(objective: ObjectiveData)
signal turn_in_objective(objective: ObjectiveData)
signal remove_objective(objective: ObjectiveData)

# Confirmation signals (when succeeded)
signal objective_assigned(objective: ObjectiveData)
signal objective_advanced(objective: ObjectiveData)
signal objective_completed(objective: ObjectiveData)
signal objective_turned_in(objective: ObjectiveData)
signal objective_removed(objective: ObjectiveData)

signal update_objective(objective: ObjectiveData)
