extends Control

@export var inventory_data: InventoryData # Player's pockets
var external_inventory_data: InventoryData # Containers

var grabbed_slot_data: InventorySlotData

const INVENTORY_SLOT = preload("uid://d3yl41a7rncgb")

@onready var player_inventory_ui: PanelContainer = %PlayerInventoryUI
@onready var pocket_slot_container: GridContainer = %PocketSlotContainer

@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI

@onready var grabbed_item_texture: TextureRect = %GrabbedItemTexture
@onready var grabbed_quantity: Label = %GrabbedQuantity
@onready var grab_timer: Timer = %GrabTimer


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
				grabbed_slot_data = slot
				grab_timer.start()
		"r_click":
			print("Right Click from %s received by inventoryUI" % slot)

func _unhandled_input(event: InputEvent) -> void:
	# Stop grabbing if click released early
	if event is InputEventMouseButton:
		if !grab_timer.is_stopped() and !event.is_pressed():
			grabbed_slot_data = null
			grab_timer.stop()

func _physics_process(_delta: float) -> void:
	if grabbed_slot_ui.visible:
		grabbed_slot_ui.position = get_local_mouse_position()

func _set_grabbed_slot():
	if !grabbed_slot_data or !grabbed_slot_data.item_data:
		print("Trying to set grabbed slot in InventoryUI but has no slot and/or item_data")
		return
	grabbed_slot_ui.position = get_local_mouse_position()
	grabbed_slot_ui.show()
	grabbed_item_texture.texture = grabbed_slot_data.item_data.texture
	if grabbed_slot_data.quantity > 1 and grabbed_slot_data.item_data.stackable:
		grabbed_quantity.show()
		grabbed_quantity.text = str(grabbed_slot_data.quantity)
	
	EventBus.removing_item_from_inventory.emit(grabbed_slot_data)

func _on_grab_timer_timeout() -> void:
	_set_grabbed_slot()
