extends Control

const TEST_EXTERNAL_INVENTORY = preload("uid://qecerdvqb2fx")

#var test_inv_data: InventoryData

var test_container_inventory_1: InventoryData
var test_container_inventory_2: InventoryData
var test_container_inventory_3: InventoryData

@onready var open_give_ui: Button = $TestPanel/VBoxContainer/OpenGiveUI
@onready var get_item: Button = $TestPanel/VBoxContainer/GetItem

@onready var external_inventory: PanelContainer = %ExternalInventory

func _ready() -> void:
	#test_inv_data = TEST_EXTERNAL_INVENTORY.duplicate(true)
	test_container_inventory_1 = InventoryData.new()
	test_container_inventory_1.slot_datas.resize(8)
	
	test_container_inventory_2 = InventoryData.new()
	test_container_inventory_2.slot_datas.resize(4)
	
	test_container_inventory_3 = InventoryData.new()
	test_container_inventory_3.slot_datas.resize(5)

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




func _on_remove_item_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://fligqycw40pd").duplicate(true)
	EventBus.removing_item.emit(test_slot.item_data, test_slot.quantity, test_slot)

func _on_get_item_pressed() -> void:
	var test_item = preload("uid://fligqycw40pd").duplicate(true)
	var new_slot = InventorySlotData.new()
	new_slot.item_data = test_item
	#test_slot.item_data = preload("uid://bu7k1xa16ud57")
	EventBus.adding_item.emit(test_item, 1)

func _on_get_item_stackable_pressed() -> void:
	var test_item = preload("uid://bu7k1xa16ud57").duplicate(true)
	var quantity = 4
	var new_slot = InventorySlotData.new()
	new_slot.item_data = test_item
	new_slot.quantity = quantity
	EventBus.adding_item.emit(test_item, quantity)


func _on_remove_item_stackable_pressed() -> void:
	var test_slot = InventorySlotData.new()
	test_slot.item_data = preload("uid://bu7k1xa16ud57").duplicate(true)
	EventBus.removing_item.emit(test_slot.item_data, test_slot.quantity, test_slot)


func _on_open_shop_ui_pressed() -> void:
# For Legal shopping
	EventBus.shopping.emit(true)

func _on_open_container_1_pressed() -> void:
	if !external_inventory.visible:
		print("TestStuff: Opening container 1")
		EventBus.setting_external_inventory.emit(test_container_inventory_1)
		return
	else:
		print("TestStuff: Closing container 1")
		EventBus.setting_external_inventory.emit(null)

func _on_open_container_2_pressed() -> void:
	if !external_inventory.visible:
		print("TestStuff: Opening container 2")
		EventBus.setting_external_inventory.emit(test_container_inventory_2)
		return
	else:
		print("TestStuff: Closing container 2")
		EventBus.setting_external_inventory.emit(null)


func _on_open_container_3_pressed() -> void:
	if !external_inventory.visible:
		print("TestStruff: Opening container 3")
		EventBus.setting_external_inventory.emit(test_container_inventory_3)
		return
	else:
		print("TestStuff: Closing container 3")
		EventBus.setting_external_inventory.emit(null)
