extends PanelContainer

const SHOP_SLOT_UI = preload("uid://cj1cyf80hrqb4")

#Create a "Pool" of loot for the inventory to pull from
@export var legal_inventory_pool: InventoryData
#var modified_pool: InventoryData
@export var illegal_inventory_pool: InventoryData
@export var legal_shop_inventory: InventoryData
@export var illegal_shop_inventory: InventoryData

var shop_inventory_data: InventoryData
var selected_slot: SlotData = null
var legal_buyback_slot: SlotData = null
var illegal_buyback_slot: SlotData = null

@onready var shop_item_name: Label = %ShopItemName
@onready var shop_item_descript: RichTextLabel = %ShopItemDescript
@onready var shop_flavor_text: RichTextLabel = %ShopFlavorText
@onready var shop_item_value: Label = %ItemValue
@onready var buy_qty_slider: HSlider = %BuyQtySlider
@onready var buy_qty: Label = %BuyQty

@onready var slot_container: GridContainer = %BuySlotContainer

@onready var shop_item_context_ui: PanelContainer = %ShopItemContextUI

@onready var buyback_ui: PanelContainer = %BuybackUI
@onready var buyback_item_texture: TextureRect = %BuybackItemTexture
@onready var buyback_quantity: Label = %BuybackQuantity
@onready var buybuack_price_label: Label = %BuybuackPriceLabel
@onready var buyback_button: Button = %BuybackButton


var legal: bool = true
var duplicate_stock_allowed: bool = false

func _ready():
	EventBus.shopping.connect(_handle_shop_ui)
	EventBus.select_item.connect(_on_item_select)
	EventBus.selling_item.connect(_sell_item)
	

## --------- SHOP POPULATION
func _handle_shop_ui(legal_shop: bool):
	
	
	# Trigger whether closing or opening ShopUI
	GameState.shopping = not GameState.shopping
	visible = GameState.shopping
	
	_clear_selected_item()
	
	# Stops if not shopping
	if not visible:
		buyback_ui.hide()
		EventBus.shop_closed.emit()
		return
	
	legal = legal_shop # Sets whether shop is Black Market or Legal
	
	if legal:
		if shop_inventory_data == legal_shop_inventory: # Prevents rerolling data each time it is opened
			return
		shop_inventory_data = null
		_set_legal_inventory()
		print("Starting a trade at the Comissary")
	
	else:
		if shop_inventory_data == illegal_shop_inventory: # Prevents rerolling data each time it is opened
			return
		shop_inventory_data = null
		_set_illegal_inventory()
		print("Starting a trade at the Black Market")

func _set_legal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	# Also removes items in the persistant stock from the pool to avoid dupes
	for i in legal_shop_inventory.slot_datas:
		var slot_index = legal_shop_inventory.slot_datas.find(i)
		var slot_data = legal_shop_inventory.slot_datas[slot_index]
		var random_slot = _select_random_item(slot_data, legal_inventory_pool)
		# If a slot was chosen, create a UI for it
		if random_slot != null:
			print("Item selected for empty shop slot: %s" % random_slot.item_data.name)
			var new_slot = SlotData.new()
			new_slot.item_data = random_slot.item_data
			new_slot.quantity = random_slot.quantity
			legal_shop_inventory.slot_datas[slot_index] = new_slot
	
	_populate_shop(legal_shop_inventory)

func _set_illegal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for i in illegal_shop_inventory.slot_datas:
		var slot_index = illegal_shop_inventory.slot_datas.find(i)
		var slot_data = illegal_shop_inventory.slot_datas[slot_index]
		var random_slot = _select_random_item(slot_data, illegal_inventory_pool)
		# If a slot was chosen, create a UI for it
		if random_slot != null:
			print("Item selected for empty shop slot: %s" % random_slot.item_data.name)
			var new_slot = SlotData.new()
			new_slot.item_data = random_slot.item_data
			new_slot.quantity = random_slot.quantity
			illegal_shop_inventory.slot_datas[slot_index] = new_slot
	_populate_shop(illegal_shop_inventory)

func _select_random_item(slot_data: SlotData, pool: InventoryData) -> SlotData:
	# Return if missing slot_data or if there are no more items in the modified_pool
	if slot_data:
		return null
	if pool.slot_datas.size() <= 0:
		return null
	# Pick a random slot
	var random_slot = pool.slot_datas.pick_random()
	 # Removes the slot so it won't be selected again
	if not duplicate_stock_allowed:
		pool.slot_datas.erase(random_slot)
	
	if random_slot:
		return random_slot
		
	return null

func _populate_shop(inv: InventoryData):
	# Clear out previous slots to avoid inconsistencies
	#shop_inventory_data = null
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

func _on_item_select(slot_data: SlotData):
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
	
	var price_each = slot_data.item_data.buy_value
	var affordable_qty = floor(GameState.money / price_each)
	
	# Reset slider, hide is non stackable
	if not slot_data.item_data.stackable:
		buy_qty_slider.hide()
		buy_qty.hide()
		buy_qty_slider.value = 1
	else:
		buy_qty_slider.show()
		buy_qty_slider.min_value = 1
		buy_qty_slider.max_value = min(slot_data.quantity, affordable_qty)
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
		
		if total_cost > GameState.money:
			shop_item_value.modulate = Color.RED
		else:
			shop_item_value.modulate = Color.WHITE

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
		
		_on_item_select(selected_slot)
		
		if selected_slot.quantity <= 0:
			var idx = shop_inventory_data.slot_datas.find(selected_slot)
			shop_inventory_data.slot_datas[idx] = null
			_clear_selected_item()
		
		_populate_shop(shop_inventory_data)

func _sell_item(sell_slot: SlotData):
	if not sell_slot or not sell_slot.item_data:
		return
	if legal:
		legal_buyback_slot = SlotData.new()
		legal_buyback_slot.item_data = sell_slot.item_data
		legal_buyback_slot.quantity = sell_slot.quantity
	else:
		illegal_buyback_slot = SlotData.new()
		illegal_buyback_slot.item_data = sell_slot.item_data
		illegal_buyback_slot.quantity = sell_slot.quantity
	_set_buyback_ui(sell_slot)
	
	GameState.money += (sell_slot.item_data.sell_value * sell_slot.quantity)
	EventBus.money_updated.emit(GameState.money)
	EventBus.removing_item.emit(sell_slot.item_data, sell_slot.quantity, null)
	

func _on_buy_qty_slider_value_changed(value: float) -> void:
	buy_qty.text = str(value)
	_update_price_display()


func _on_close_shop_button_pressed() -> void:
	_handle_shop_ui(legal)

func _set_buyback_ui(sell_slot: SlotData):
	buyback_ui.show()
	buyback_item_texture.texture = sell_slot.item_data.texture
	buyback_quantity.text  = str(sell_slot.quantity)
	buybuack_price_label.text = "%s" % str(sell_slot.item_data.sell_value * sell_slot.quantity)
	buyback_ui.tooltip_text = sell_slot.item_data.name

func _on_buyback_button_pressed() -> void:
	var buyback_slot: SlotData = null
	if legal: buyback_slot = legal_buyback_slot
	else: buyback_slot = illegal_buyback_slot
	if not buyback_slot:
		return
	
	var cost = buyback_slot.item_data.sell_value * buyback_slot.quantity
	if GameState.money >= cost:
		GameState.money -= cost
		EventBus.money_updated.emit(GameState.money)
		EventBus.adding_item.emit(buyback_slot.item_data, buyback_slot.quantity)
	
		if legal:
			legal_buyback_slot = null
		else:
			illegal_buyback_slot = null
		buyback_ui.hide()
	else:
		print("Too poor to buy your own stuff back, how pathetic")
