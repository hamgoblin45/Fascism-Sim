extends Node



signal inventory_interacted(inv: InventoryData, slot: PanelContainer, slot_data: InventorySlotData, type: String) # Goes to managers, which then emit confirmation signals like "select_item"
signal inventory_item_updated(inv_data: InventorySlotData, index: int) # Emit from Manager to confirm something changed a slot

signal removing_item(item: InventoryItemData, qty: int, slot: InventorySlotData) # Requests removing an item from an inventory

signal adding_item(item_data: InventoryItemData, qty: int) # Requests adding an item to an inventory

signal update_grabbed_slot(slot: InventorySlotData) # for picking up items between inventory slots. emit null to clear out

signal request_pockets_inventory # Sent by UI when it's ready to get data
signal setting_pockets_inventory(inv: InventoryData)
signal pockets_inventory_set(inv: InventoryData)

signal setting_external_inventory(inv_data: InventoryData) # Populates container inventories
signal external_inventory_set(inv_data: InventoryData) # Confirms an external inventory was loaded

signal shopping(legal: bool) # Opens up either the legal shop or the black market
signal shop_closed # Resets player inventory slots if they had been disabled for selling
signal selling_item(slot: InventorySlotData) # Requests sale

signal select_item(slot_data: InventorySlotData) # When clicking an item in an inventory, used to set context ui
signal open_split_stack_ui(slot_data: InventorySlotData)
signal splitting_item_stack(grab_slot_data: InventorySlotData) # Requests splitting a slot
signal item_stack_split(slot_data: InventorySlotData, orig_slot: InventorySlotData) # Confirms a slot was split

signal item_discarded(slot_data: InventorySlotData, drop_position: Vector2)

signal using_item(slot_data: InventorySlotData) # Requests use of an item

signal money_updated(new_total: float)

signal dialogue_started # will likely be a Dialogic signal once connected to dialogue system
signal dialogue_ended # will likely be a Dialogic signal once connected to dialogue system
