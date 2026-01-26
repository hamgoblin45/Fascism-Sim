extends PanelContainer

const INVENTORY_SLOT = preload("uid://d3yl41a7rncgb")

@export var inventory_data: InventoryData

@onready var slot_container: GridContainer = %PocketSlotContainer

@onready var item_context_ui: PanelContainer = %PocketItemContextUI
@onready var split_stack_ui: PanelContainer = %PocketsSplitStackUI

@onready var money_value: Label = %MoneyValue


func _ready() -> void:
	EventBus.pockets_inventory_set.connect(_set_inventory)
	EventBus.money_updated.connect(_update_money)
	EventBus.request_pockets_inventory.emit()

func _set_inventory(inv_data: InventoryData):
	# Clears out old slots
	for child in slot_container.get_children():
		child.queue_free()
	for slot in inv_data.slot_datas:
		var slot_ui = INVENTORY_SLOT.instantiate()
		slot_container.add_child(slot_ui)
		slot_ui.set_slot_data(slot)
		slot_ui.parent_inventory = inv_data
	
	money_value.text = str(snapped(GameState.money, 0.1))
	item_context_ui.inventory_data = inv_data
	print("PocketsInventoryUI: Set inventory w/ resource: %s" % inventory_data)


func _update_money(value: float):
	money_value.text = str(snapped(value, 0.01))
