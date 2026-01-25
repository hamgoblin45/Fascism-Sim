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
	EventBus.select_item.connect(_on_item_select)

func _set_inventory(inv_data: InventoryData):
	print("Setting pocket inventory")
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

func _on_item_select(slot: InventorySlotData):
	print("Pockets inventory item selected")
	for slot_ui in slot_container.get_children():
		item_context_ui.set_context_menu(null)
		#slot_ui.selected_panel.hide()
		#if inv != inventory_data:
			#return
		if slot_ui.slot_data and slot_ui.slot_data.item_data and slot_ui.slot_data == slot:
			if slot_ui.selected_panel.visible:
				slot_ui.selected_panel.hide()
				item_context_ui.set_context_menu(null)
				return
			print("Setting context menu")
			item_context_ui.set_context_menu(slot)
			#slot_ui.selected_panel.show()
			return
			

func _update_money(value: float):
	money_value.text = str(snapped(value, 0.01))
