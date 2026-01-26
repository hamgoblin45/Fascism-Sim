extends Control

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			EventBus.select_item.emit(null) # Closes any item context ui if clicking outside of inventory ui
			
			EventBus.inventory_interacted.emit(null, null, null, "world_click") # Tells the inventory a player is clicking outside and potentially discarding an item
