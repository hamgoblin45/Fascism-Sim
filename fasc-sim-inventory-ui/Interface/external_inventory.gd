extends PanelContainer

const INVENTORY_SLOT = preload("uid://d3yl41a7rncgb")

@export var inventory_data: InventoryData

@onready var name_label: Label = %ExternalNameLabel
@onready var slot_container: GridContainer = %ExternalSlotContainer

@onready var item_context_ui: PanelContainer = %ExternalItemContextUI
@onready var split_stack_ui: PanelContainer = %ExternalSplitStackUI


func _ready() -> void:
	EventBus.external_inventory_set.connect(_set_inventory)
	EventBus.select_item.connect(_on_item_select)


func _set_inventory(inv_data: InventoryData):
	inventory_data = inv_data
	for slot in slot_container.get_children():
		slot.queue_free()
	if inventory_data == null:
		hide()
		return
	show()
	for slot in inv_data.slot_datas:
		var slot_ui = INVENTORY_SLOT.instantiate()
		slot_container.add_child(slot_ui)
		slot_ui.parent_inventory = inv_data
		slot_ui.set_slot_data(slot)

func _on_item_select(slot: InventorySlotData):
	for slot_ui in slot_container.get_children():
		slot_ui.selected_panel.hide()
	
	if inventory_data and inventory_data.slot_datas.has(slot):
		for slot_ui in slot_container.get_children():
			if slot_ui.slot_data == slot:
				slot_ui.selected_panel.show()
			item_context_ui.set_context_menu(slot)
			return
