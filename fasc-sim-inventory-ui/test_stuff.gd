extends Control

const TEST_EXTERNAL_INVENTORY = preload("uid://qecerdvqb2fx")

@onready var open_give_ui: Button = $TestPanel/VBoxContainer/OpenGiveUI
@onready var get_item: Button = $TestPanel/VBoxContainer/GetItem


var in_dialogue: bool = false

func _ready() -> void:
	EventBus.giving_item.connect(_on_give_item)

func _on_open_give_ui_pressed() -> void:
	in_dialogue = !in_dialogue
	%DialogueLabel.visible = in_dialogue
	if in_dialogue:
		EventBus.dialogue_started.emit()
		
	else:
		EventBus.dialogue_ended.emit()

func _on_give_item(slot: InventorySlotData):
	%GiveLabel.show()
	%GiveLabel.text = "You gave the npc a[n] %s" % slot.item_data.name
	await get_tree().create_timer(2.0).timeout
	%GiveLabel.hide()

func _on_open_container_pressed() -> void:
	if !%ExternalInventory.visible:
		EventBus.setting_external_inventory.emit(TEST_EXTERNAL_INVENTORY)
	else:
		EventBus.setting_external_inventory.emit(null)


func _on_remove_item_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://fligqycw40pd")
	EventBus.removing_item_from_inventory.emit(test_slot)

func _on_get_item_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://fligqycw40pd")
	#test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.adding_item_to_inventory.emit(test_slot)

func _on_get_item_stackable_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://bu7k1xa16ud57")
	test_slot.quantity = 4
	EventBus.adding_item_to_inventory.emit(test_slot)


func _on_remove_item_stackable_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.removing_item_from_inventory.emit(test_slot)
