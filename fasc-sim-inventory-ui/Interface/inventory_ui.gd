extends Control





func _ready() -> void:
	EventBus.inventory_interacted.connect(_on_inventory_interact)




func _on_inventory_interact(slot: InventorySlotData, type: String):
	match type:
		"click":
			print("Click from %s received by inventoryUI" % slot)
		"r_click":
			print("Right Click from %s received by inventoryUI" % slot)
