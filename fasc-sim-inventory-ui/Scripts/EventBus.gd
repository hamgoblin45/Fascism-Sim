extends Node



signal inventory_interacted(inv: InventoryData, slot: PanelContainer, slot_data: InventorySlotData, type: String)
signal inventory_item_updated(slot_data: InventorySlotData)
signal removing_item_from_inventory(_clear_slot_data: InventorySlotData)
signal adding_item_to_inventory(item_data: InventorySlotData, qty: int)

signal setting_external_inventory(inv_data: InventoryData)
signal shopping(legal: bool)
signal selling_item(slot: InventorySlotData)
signal item_sold(slot: InventorySlotData)

signal open_item_context_menu(inv: InventoryData, slot_data: InventorySlotData)
signal open_split_stack_ui(slot_data: InventorySlotData)
signal splitting_item_stack(slot_data: InventorySlotData, orig_slot: InventorySlotData)

signal using_item(slot_data: InventorySlotData)
signal item_used(slot_data: InventorySlotData)

signal dialogue_started # will likely be a Dialogic signal once connected to dialogue system
signal giving_item(slot_data: InventorySlotData)
signal dialogue_ended
