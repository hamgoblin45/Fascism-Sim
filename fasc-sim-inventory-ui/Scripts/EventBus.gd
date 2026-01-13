extends Node



signal inventory_interacted(slot: PanelContainer, slot_data: InventorySlotData, type: String)
signal inventory_item_updated(slot_data: InventorySlotData)
signal removing_item_from_inventory(_clear_slot_data: InventorySlotData)
signal adding_item_to_inventory(stack_data: InventorySlotData)

signal setting_external_inventory(inv_data: InventoryData)

signal open_item_context_menu(slot_data: InventorySlotData)
signal open_split_stack_ui(slot_data: InventorySlotData)
signal splitting_item_stack(slot_data: InventorySlotData, orig_slot_data: InventorySlotData)

signal using_item(slot_data: InventorySlotData)
signal item_used(slot_data: InventorySlotData)

signal dialogue_started # will likely be a Dialogic signal once connected to dialogue system
signal giving_item(slot_data: InventorySlotData)
signal dialogue_ended
