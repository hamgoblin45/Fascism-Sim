extends Control

const TEST_EXTERNAL_INVENTORY = preload("uid://qecerdvqb2fx")

var test_inv_data: InventoryData

@onready var open_give_ui: Button = $TestPanel/VBoxContainer/OpenGiveUI
@onready var get_item: Button = $TestPanel/VBoxContainer/GetItem

@onready var external_inventory: PanelContainer = %ExternalInventory

func _ready() -> void:
	test_inv_data = TEST_EXTERNAL_INVENTORY.duplicate(true)

func _on_open_give_ui_pressed() -> void:
	GameState.in_dialogue = !GameState.in_dialogue
	%DialogueLabel.visible = GameState.in_dialogue
	if GameState.in_dialogue:
		EventBus.dialogue_started.emit()
		
	else:
		EventBus.dialogue_ended.emit()

func _on_give_item(slot: InventorySlotData):
	%GiveLabel.show()
	%GiveLabel.text = "You gave the npc a[n] %s" % slot.item_data.name
	await get_tree().create_timer(2.0).timeout
	%GiveLabel.hide()

func _on_open_container_pressed() -> void:
	if !external_inventory.visible:
		print("Opening continare")
		EventBus.setting_external_inventory.emit(test_inv_data)
		return
	else:
		print("Closing container")
		EventBus.setting_external_inventory.emit(null)


func _on_remove_item_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://fligqycw40pd")
	EventBus.removing_item.emit(test_slot.item_data, test_slot.quantity, test_slot)

func _on_get_item_pressed() -> void:
	var test_item = preload("uid://fligqycw40pd")
	#test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.adding_item.emit(test_item, 1)

func _on_get_item_stackable_pressed() -> void:
	var test_item = preload("uid://bu7k1xa16ud57")
	var quantity = 4
	EventBus.adding_item.emit(test_item, quantity)


func _on_remove_item_stackable_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.removing_item.emit(test_slot.item_data, test_slot.quantity, test_slot)


func _on_open_shop_ui_pressed() -> void:
# For Legal shopping
	EventBus.shopping.emit(true)
