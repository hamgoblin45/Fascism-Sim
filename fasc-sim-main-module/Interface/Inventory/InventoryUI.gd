extends Control

const SLOT_SCENE = preload("uid://d3yl41a7rncgb")
const SHOP_SLOT_SCENE = preload("uid://cj1cyf80hrqb4")

# Pockets / Hotbar
@onready var pockets_ui: PanelContainer = %PocketsInventoryUI
@onready var pockets_grid: GridContainer = $PocketsInventoryUI/PocketsMasterContainer/BarDetailsRow/PocketsContainer/SlotsPanel/PocketSlotContainer

@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI

# External
@onready var external_ui: PanelContainer = %ExternalInventoryUI
@onready var external_grid: GridContainer = $ExternalInventoryUI/HBoxContainer/VBoxContainer/SlotsPanel/ExternalSlotContainer

# Shop
@onready var shop_ui: PanelContainer = %ShopUI
@onready var shop_grid: GridContainer = $ShopUI/HBoxContainer/ShopPanel/VBoxContainer/SlotsPanel/BuySlotContainer

# Context
@onready var pocket_item_context_ui: PanelContainer = $PocketsInventoryUI/PocketsMasterContainer/BarDetailsRow/PocketItemContextUI
@onready var external_item_context_ui: PanelContainer = $ExternalInventoryUI/HBoxContainer/ExternalItemContextUI
@onready var shop_item_context_ui: PanelContainer = $ShopUI/HBoxContainer/ShopItemContextUI

func _ready():
	EventBus.pockets_inventory_set.connect(_on_pockets_set)
	EventBus.external_inventory_set.connect(_on_external_set)
	EventBus.inventory_item_updated.connect(_on_item_updated)
	# Also put shop connections here, not set up yet
	EventBus.select_item.connect(_on_context_ui_set)
	
	# Clear UIs - might need to connect to control interface
	external_ui.hide()
	external_item_context_ui.hide()
	shop_ui.hide()
	shop_item_context_ui.hide()
	pocket_item_context_ui.hide()

	## --- SETUP ---
func _on_pockets_set(inventory_data: InventoryData):
	_populate_grid(pockets_grid, inventory_data)

func _on_external_set(inventory_data: InventoryData):
	if inventory_data:
		external_ui.show()
		_populate_grid(external_grid, inventory_data)
	else:
		external_ui.hide()
		_clear_grid(external_grid)

func _populate_grid(container: GridContainer, inventory_data: InventoryData):
	_clear_grid(container)
	for i in range(inventory_data.slots.size()):
		var slot_ui = SLOT_SCENE.instantiate()
		container.add_child(slot_ui)
		
		slot_ui.parent_inventory = inventory_data
		slot_ui.slot_index = i
		
		if inventory_data.slots[i]:
			slot_ui.set_slot_data(inventory_data.slots[i])

func _clear_grid(container: GridContainer):
	for child in container.get_children():
		child.queue_free()

## --- UPDATING ----

func _on_item_updated(inventory_data: InventoryData, index: int):
	# Figure out which container/inv owns the data
	var container: GridContainer = null
	if inventory_data == GameState.pockets_inventory:
		container = pockets_grid
	elif external_ui.visible and external_ui.inventory_data == inventory_data:
		container = external_grid
	elif shop_ui.visible and shop_ui.shop_inventory_data == inventory_data:
		container = shop_grid
	
	# Match the indexes and set the correllating slot
	if container and index < container.get_child_count():
		var slot_ui = container.get_child(index)
		slot_ui.set_slot_data(inventory_data.slots[index])

## --- CONTEXT UIs ----
func _on_context_ui_set(slot_data: SlotData):
	var context_ui: PanelContainer = null
	for slot in GameState.pockets_inventory.slots:
		if slot == slot_data:
			context_ui = pocket_item_context_ui
		
	if external_ui.visible:
		for slot in external_ui.inventory_data.slots:
			if slot == slot_data:
				context_ui = external_item_context_ui
	
	elif shop_ui.visible:
		for slot in shop_ui.shop_inventory_data.slots:
			if slot == slot_data:
				context_ui = shop_item_context_ui
	
	if context_ui:
		context_ui.set_context_menu(slot_data)
	else:
		pocket_item_context_ui.set_context_menu(null)
		external_item_context_ui.set_context_menu(null)
		shop_item_context_ui.set_context_menu(null)


## --- SHOP VISIBILITY ---
func _on_shop_opened(shop_data: InventoryData):
	shop_ui.show()
	_populate_grid(shop_grid, shop_data)

func _on_shop_closed():
	shop_ui.hide()

## -- DISCARD ZONE ---
# Should drop items into the world if clicking outside of UI
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Click discovered outside of UI")
			EventBus.select_item.emit(null) # Closes any item context ui if clicking outside of inventory ui
			
			EventBus.inventory_interacted.emit(null, null, null, "world_click") # Tells the inventory a player is clicking outside and potentially discarding an item
