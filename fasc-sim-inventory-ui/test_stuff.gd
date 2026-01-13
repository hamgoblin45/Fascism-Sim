extends Control

@onready var open_give_ui: Button = $TestPanel/VBoxContainer/OpenGiveUI
@onready var get_item: Button = $TestPanel/VBoxContainer/GetItem

var in_dialogue: bool = false

func _on_open_give_ui_pressed() -> void:
	in_dialogue = !in_dialogue
	if in_dialogue:
		EventBus.dialogue_started.emit()
	else:
		EventBus.dialogue_ended.emit()


func _on_get_item_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://fligqycw40pd")
	#test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.adding_item_to_inventory.emit()
