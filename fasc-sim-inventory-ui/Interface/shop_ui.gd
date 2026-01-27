extends PanelContainer

const SHOP_SLOT_UI = preload("uid://cj1cyf80hrqb4")

#Create a "Pool" of loot for the inventory to pull from
@export var legal_inventory_pool: InventoryData
@export var illegal_inventory_pool: InventoryData
@export var legal_shop_inventory: InventoryData
@export var illegal_shop_inventory: InventoryData

var shop_inventory_data: InventoryData
var selected_slot: InventorySlotData = null
var buyback_slot: InventorySlotData

@onready var shop_item_name: Label = %ShopItemName
@onready var shop_item_descript: RichTextLabel = %ShopItemDescript
@onready var shop_flavor_text: RichTextLabel = %ShopFlavorText
@onready var shop_item_value: Label = %ItemValue
@onready var buy_qty_slider: HSlider = %BuyQtySlider
@onready var buy_qty: Label = %BuyQty

@onready var slot_container: GridContainer = %BuySlotContainer

@onready var shop_item_context_ui: PanelContainer = %ShopItemContextUI

var legal: bool = true


func _ready():
	EventBus.shopping.connect(_handle_shop_ui)
	EventBus.select_item.connect(_on_item_select)
	EventBus.selling_item.connect(_sell_item)
	

## --------- SHOP POPULATION
func _handle_shop_ui(legal_shop: bool):
	# Clear stuff out
	shop_inventory_data = null
	_clear_selected_item()
	
	# Trigger whether closing or opening ShopUI
	GameState.shopping = not GameState.shopping
	visible = GameState.shopping
	
	# Stops if not shopping
	if not visible:
		EventBus.shop_closed.emit()
		return
	
	legal = legal_shop # Sets whether shop is Black Market or Legal
	
	if legal:
		_set_legal_inventory()
		print("Starting a trade at the Comissary")
	
	else:
		_set_illegal_inventory()
		print("Starting a trade at the Black Market")

func _set_legal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for i in legal_shop_inventory.slot_datas:
		var slot_index = legal_shop_inventory.slot_datas.find(i)
		var slot_data = legal_shop_inventory.slot_datas[slot_index]
		if not slot_data or not slot_data.item_data:
			print("Empty slot in legal inventory set")
			var random_slot = legal_inventory_pool.slot_datas.pick_random()
			print("Item selected for empty shop slot: %s" % random_slot.item_data.name)
			var new_slot = InventorySlotData.new()
			new_slot.item_data = random_slot.item_data
			new_slot.quantity = random_slot.quantity
			legal_shop_inventory.slot_datas[slot_index] = new_slot
	_populate_shop(legal_shop_inventory)

func _set_illegal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for i in illegal_shop_inventory.slot_datas:
		var slot_index = illegal_shop_inventory.slot_datas.find(i)
		var slot_data = illegal_shop_inventory.slot_datas[slot_index]
		if not slot_data or not slot_data.item_data:
			print("Empty slot in illegal inventory set")
			var random_slot = illegal_inventory_pool.slot_datas.pick_random()
			print("Item selected for empty shop slot: %s" % random_slot.item_data.name)
			var new_slot = InventorySlotData.new()
			new_slot.item_data = random_slot.item_data
			new_slot.quantity = random_slot.quantity
			illegal_shop_inventory.slot_datas[slot_index] = new_slot
	_populate_shop(illegal_shop_inventory)

func _populate_shop(inv: InventoryData):
	# Clear out previous slots to avoid inconsistencies
	shop_inventory_data = null
	for child in slot_container.get_children():
		child.queue_free()
	
	shop_inventory_data = inv
# Create a slot for each space in slot_datas, even if no slot_data
	for slot_data in inv.slot_datas:
		var new_slot_ui = SHOP_SLOT_UI.instantiate()
		slot_container.add_child(new_slot_ui)
		new_slot_ui.parent_inventory = inv
		if slot_data:
			new_slot_ui.set_slot_data(slot_data)
	
## ------- SELECTED ITEM
func _clear_selected_item():
	selected_slot = null
	shop_item_context_ui.hide()
	buy_qty_slider.hide()
	buy_qty.hide()
	for slot_ui in slot_container.get_children():
		slot_ui.selected_panel.hide()

func _on_item_select(slot_data: InventorySlotData):
	if not shop_inventory_data or not shop_inventory_data.slot_datas.has(slot_data):
		print("Shop inv doesn't have slot")
		_clear_selected_item()
		return
	
	if selected_slot != slot_data:
		_clear_selected_item()
	
	if not slot_data:
		return

	shop_item_context_ui.show()
	selected_slot = slot_data
	
	shop_item_name.text = slot_data.item_data.name
	shop_item_descript.text = slot_data.item_data.description
	shop_flavor_text.text = slot_data.item_data.flavor_text
	
	
	if not slot_data.item_data.stackable:
		buy_qty.hide()
		buy_qty_slider.value = 1
		buy_qty_slider.hide()
	else:
		buy_qty_slider.show()
		buy_qty_slider.min_value = 1
		buy_qty_slider.max_value = slot_data.quantity
		buy_qty_slider.value = 1
	
	_update_price_display()
	
	for slot_ui in slot_container.get_children():
		slot_ui.selected_panel.hide()
		if slot_ui.slot_data and slot_ui.slot_data == slot_data:
			slot_ui.selected_panel.show()

func _update_price_display():
	if selected_slot and selected_slot.item_data:
		var amount_to_buy = int(buy_qty_slider.value)
		var total_cost = selected_slot.item_data.buy_value * amount_to_buy
		if amount_to_buy > 1:
			shop_item_value.text = "Buy %s for %s" % [str(amount_to_buy), str(total_cost)]
		else:
			shop_item_value.text = "Buy for %s" % str(total_cost)

## ------------- BUYING

func _on_buy_button_pressed() -> void:
	if selected_slot and selected_slot.item_data:
		var amount_to_buy = int(buy_qty_slider.value)
		var total_cost = selected_slot.item_data.buy_value * amount_to_buy
		
		if GameState.money < total_cost:
			print("TOO POOR!")
			return
		
		GameState.money -= total_cost
		EventBus.money_updated.emit(GameState.money)
		
		EventBus.adding_item.emit(selected_slot.item_data, amount_to_buy)
		
		selected_slot.quantity -= amount_to_buy # Reduces shop stock by amount
		
		if selected_slot.quantity <= 0:
			var idx = shop_inventory_data.slot_datas.find(selected_slot)
			shop_inventory_data.slot_datas[idx] = null
			_clear_selected_item()
		
		_populate_shop(shop_inventory_data)

func _sell_item(sell_slot: InventorySlotData):
	if not sell_slot or not sell_slot.item_data:
		return
	
	GameState.money += (sell_slot.item_data.sell_value * sell_slot.quantity)
	EventBus.money_updated.emit(GameState.money)
	EventBus.removing_item.emit(sell_slot.item_data, sell_slot.quantity, null)
	

func _on_buy_qty_slider_value_changed(value: float) -> void:
	buy_qty.text = str(value)
	_update_price_display()


func _on_close_shop_button_pressed() -> void:
	_handle_shop_ui(legal)
