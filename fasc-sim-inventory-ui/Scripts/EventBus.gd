extends Node


signal inventory_interacted(slot_data: InventorySlotData, type: String)
signal inventory_item_updated(slot_data: InventorySlotData)
signal removing_item_from_inventory(_clear_slot_data: InventorySlotData)
