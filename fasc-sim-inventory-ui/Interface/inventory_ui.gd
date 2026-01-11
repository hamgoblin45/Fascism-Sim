extends Control

@export var inventory_data: InventoryData # Player's pockets
var external_inventory_data: InventoryData # Containers

const INVENTORY_SLOT = preload("uid://d3yl41a7rncgb")

@onready var player_inventory_ui: PanelContainer = %PlayerInventoryUI
@onready var pocket_slot_container: GridContainer = %PocketSlotContainer


func _ready() -> void:
	EventBus.inventory_interacted.connect(_on_inventory_interact)
	_set_player_inventory()


func _set_player_inventory():
	for child in pocket_slot_container.get_children():
		child.queue_free()
	for slot in inventory_data.slot_datas:
		var slot_ui = INVENTORY_SLOT.instantiate()
		pocket_slot_container.add_child(slot_ui)
		slot_ui.set_slot_data(slot)

func _on_inventory_interact(slot: InventorySlotData, type: String):
	match type:
		"click":
			print("Click from %s received by inventoryUI" % slot)
			if slot and slot.item_data:
				print("Clicked %s" % slot.item_data.name)
		"r_click":
			print("Right Click from %s received by inventoryUI" % slot)
