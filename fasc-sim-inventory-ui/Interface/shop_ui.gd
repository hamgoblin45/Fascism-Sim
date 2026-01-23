extends PanelContainer

const SHOP_SLOT_UI = preload("uid://cj1cyf80hrqb4")

#Create a "Pool" of loot for the inventory to pull from
@export var legal_inventory_pool: InventoryData
@export var illegal_inventory_pool: InventoryData
@export var legal_shop_inventory: InventoryData
@export var illegal_shop_inventory: InventoryData

var selected_item: InventorySlotData = null

@onready var shop_item_name: Label = %ShopItemName
@onready var shop_item_descript: RichTextLabel = %ShopItemDescript
@onready var shop_flavor_text: RichTextLabel = %ShopFlavorText
@onready var shop_item_value: Label = %ShopItemValue
@onready var buy_qty_slider: HSlider = %BuyQtySlider
@onready var buy_qty: Label = %BuyQty

@onready var slot_container: GridContainer = %BuySlotContainer

@onready var shop_item_context_ui: PanelContainer = %ShopItemContextUI

@onready var buy_button: Button = %BuyButton

var legal: bool = true


func _ready():
	EventBus.shopping.connect(_handle_shop_ui)
	EventBus.inventory_interacted.connect(_on_inventory_interact)

func _handle_shop_ui(legal_shop: bool):
	GameState.shopping = not GameState.shopping
	visible = GameState.shopping
	legal = legal_shop
	if legal:
		_set_legal_inventory()
		print("Starting a trade at the Comissary")
	
	else:
		_set_illegal_inventory()
		print("Starting a trade at the Black Market")

func _set_legal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for slot in legal_shop_inventory.slot_datas:
		if slot == null:
			var item = legal_inventory_pool.slot_datas.pick_random().item_data
			var new_slot = InventorySlotData.new()
			new_slot.item_data = item
	_populate_shop(legal_shop_inventory)

func _set_illegal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for slot in illegal_shop_inventory.slot_datas:
		if slot == null:
			var item = illegal_inventory_pool.slot_datas.pick_random().item_data
			var new_slot = InventorySlotData.new()
			new_slot.item_data = item
	_populate_shop(illegal_shop_inventory)

func _populate_shop(inv: InventoryData):
	# Clear out previous slots to avoid inconsistencies
	for child in slot_container.get_children():
		child.queue_free()
	
# Create a slot for each space in slot_datas, even if no slot_data
	for slot_data in inv.slot_datas:
		var new_slot_ui = SHOP_SLOT_UI.instantiate()
		var new_slot_data = InventorySlotData.new()
		slot_container.add_child(new_slot_ui)
		new_slot_ui.parent_inventory = inv
		if slot_data and slot_data.item_data:
			new_slot_data.item_data = slot_data.item_data
			new_slot_data.quantity = slot_data.quantity
			new_slot_ui.set_slot_data(new_slot_data)
		

func _set_sellable_inventory():
	pass

func _on_inventory_interact(inv: InventoryData, panel: PanelContainer, slot_data: InventorySlotData, interact_type: String):
	if legal and inv != legal_shop_inventory:
		return
	elif not legal and inv != illegal_shop_inventory:
		return
	
	match interact_type:
		"click":
			if slot_data != null and slot_data.item_data:
				_select_shop_item(slot_data)
				panel.selected_panel.show()

func _clear_select_item():
	selected_item = null
	shop_item_context_ui.hide()
	buy_qty_slider.hide()
	buy_qty.hide()

func _select_shop_item(slot_data: InventorySlotData):
	_clear_select_item()
	shop_item_context_ui.show()
	selected_item = slot_data
	print("Setting item context menu in inventory")
	shop_item_name.text = slot_data.item_data.name
	shop_item_descript.text = slot_data.item_data.description
	shop_flavor_text.text = slot_data.item_data.flavor_text
	
	if slot_data.item_data.stackable and slot_data.quantity > 1:
		buy_qty_slider.show()
		buy_qty_slider.value = 1
		buy_qty.text = "1"
		buy_qty_slider.max_value = slot_data.quantity


func _on_buy_button_pressed() -> void:
	if selected_item:
		if GameState.money < selected_item.item_data.buy_value:
			print("TOO POOR!")
			return
		GameState.money -= selected_item.item_data.buy_value 
		EventBus.adding_item_to_inventory.emit(selected_item, buy_qty_slider.value)
		_clear_select_item()


func _on_buy_qty_slider_value_changed(value: float) -> void:
	buy_qty.text = str(value)
