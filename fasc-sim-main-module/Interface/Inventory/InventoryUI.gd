extends Control
class_name InventoryUI

const SLOT_SCENE = preload("uid://d3yl41a7rncgb") # Ensure this is correct UID/Path for inventory_slot_ui.tscn
# const SHOP_SLOT_SCENE = preload("uid://cj1cyf80hrqb4") # Uncomment when needed

# Pockets / Hotbar
@onready var pockets_ui: PanelContainer = %PocketsInventoryUI
@onready var pockets_grid: GridContainer = $PocketsInventoryUI/PocketsMasterContainer/BarDetailsRow/PocketsContainer/SlotsPanel/PocketSlotContainer

# Grabbed Item Cursor
@onready var grabbed_slot_ui: PanelContainer = %GrabbedSlotUI

# External
@onready var external_ui: PanelContainer = %ExternalInventoryUI
@onready var external_grid: GridContainer = $ExternalInventoryUI/HBoxContainer/VBoxContainer/SlotsPanel/ExternalSlotContainer

# Shop
@onready var shop_ui: PanelContainer = %ShopUI
@onready var shop_grid: GridContainer = $ShopUI/HBoxContainer/ShopPanel/VBoxContainer/SlotsPanel/BuySlotContainer

# Context Menus
@onready var pocket_item_context_ui: PanelContainer = $PocketsInventoryUI/PocketsMasterContainer/BarDetailsRow/PocketItemContextUI
@onready var external_item_context_ui: PanelContainer = $ExternalInventoryUI/HBoxContainer/ExternalItemContextUI
@onready var shop_item_context_ui: PanelContainer = $ShopUI/HBoxContainer/ShopItemContextUI

func _ready() -> void:
	# Signal Connections
	EventBus.pockets_inventory_set.connect(_on_pockets_set)
	EventBus.external_inventory_set.connect(_on_external_set)
	EventBus.inventory_item_updated.connect(_on_item_updated)
	EventBus.select_item.connect(_on_context_ui_set)
	EventBus.update_grabbed_slot.connect(_on_grabbed_slot_updated)
	
	# Initial State: Hide secondary UIs
	external_ui.hide()
	external_item_context_ui.hide()
	shop_ui.hide()
	shop_item_context_ui.hide()
	pocket_item_context_ui.hide()
	
	if grabbed_slot_ui:
		grabbed_slot_ui.hide()

func _process(_delta: float) -> void:
	# Make the grabbed item follow the mouse
	if grabbed_slot_ui.visible:
		grabbed_slot_ui.global_position = get_global_mouse_position() + Vector2(15, 15)

## --- SETUP & POPULATION ---

func _on_pockets_set(inventory_data: InventoryData) -> void:
	_populate_grid(pockets_grid, inventory_data)

func _on_external_set(inventory_data: InventoryData) -> void:
	if inventory_data:
		external_ui.show()
		_populate_grid(external_grid, inventory_data)
	else:
		external_ui.hide()
		_clear_grid(external_grid)

func _populate_grid(container: GridContainer, inventory_data: InventoryData) -> void:
	_clear_grid(container)
	
	for i in range(inventory_data.slots.size()):
		var slot_ui = SLOT_SCENE.instantiate()
		container.add_child(slot_ui)
		
		# Set metadata for the UI slot
		slot_ui.parent_inventory = inventory_data
		slot_ui.slot_index = i
		
		# Render data if it exists
		if inventory_data.slots[i]:
			slot_ui.set_slot_data(inventory_data.slots[i])

func _clear_grid(container: GridContainer) -> void:
	for child in container.get_children():
		child.queue_free()

## --- UPDATES ---

func _on_item_updated(inventory_data: InventoryData, index: int) -> void:
	var container: GridContainer = null
	
	# Identify which grid corresponds to the updated inventory data
	if inventory_data == GameState.pockets_inventory:
		container = pockets_grid
	elif external_ui.visible and external_ui.inventory_data == inventory_data: # Assumes ExternalUI script has inventory_data property
		container = external_grid
	elif shop_ui.visible and shop_ui.shop_inventory_data == inventory_data: # Assumes ShopUI script has shop_inventory_data property
		container = shop_grid
	
	# Update the specific slot UI
	if container and index < container.get_child_count():
		var slot_ui = container.get_child(index)
		slot_ui.set_slot_data(inventory_data.slots[index])

func _on_grabbed_slot_updated(slot_data: SlotData) -> void:
	if slot_data:
		grabbed_slot_ui.show()
		grabbed_slot_ui.set_slot_data(slot_data)
	else:
		grabbed_slot_ui.hide()

## --- CONTEXT MENUS ---

func _on_context_ui_set(slot_data: SlotData) -> void:
	_hide_all_context_menus()
	
	if slot_data == null: return

	# Find where the clicked slot lives and show the appropriate menu
	if _is_slot_in_inventory(slot_data, GameState.pockets_inventory):
		pocket_item_context_ui.set_context_menu(slot_data)
		pocket_item_context_ui.show()
		
	elif external_ui.visible and _is_slot_in_inventory(slot_data, external_ui.inventory_data):
		external_item_context_ui.set_context_menu(slot_data)
		external_item_context_ui.show()
		
	elif shop_ui.visible and _is_slot_in_inventory(slot_data, shop_ui.shop_inventory_data):
		shop_item_context_ui.set_context_menu(slot_data)
		shop_item_context_ui.show()

func _is_slot_in_inventory(slot: SlotData, inv: InventoryData) -> bool:
	if not inv: return false
	return inv.slots.has(slot)

func _hide_all_context_menus() -> void:
	pocket_item_context_ui.hide()
	external_item_context_ui.hide()
	shop_item_context_ui.hide()

## --- INPUT HANDLING (Discard Zone) ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("UI: Clicked outside inventory panels (Discard Zone)")
			
			# Close context menu
			EventBus.select_item.emit(null) 
			
			# If holding an item, this counts as dropping it
			if grabbed_slot_ui.visible:
				EventBus.inventory_interacted.emit(null, null, null, "world_click")
