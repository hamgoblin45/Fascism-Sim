extends PanelContainer
class_name ShopUI

const SHOP_SLOT_UI = preload("uid://cj1cyf80hrqb4")

@export var legal_inventory_pool: InventoryData
@export var illegal_inventory_pool: InventoryData
@export var legal_shop_inventory: InventoryData
@export var illegal_shop_inventory: InventoryData

var shop_inventory_data: InventoryData
var selected_slot: SlotData = null
var legal_buyback_slot: SlotData = null
var illegal_buyback_slot: SlotData = null
var legal: bool = true

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
@onready var buyback_price_label: Label = %BuybuackPriceLabel

func _ready():
	EventBus.open_specific_shop.connect(_on_open_specific_shop)
	EventBus.select_item.connect(_on_item_select)
	EventBus.selling_item.connect(_sell_item)
	hide()

func _on_open_specific_shop(inv_data: InventoryData, is_legal: bool):
	GameState.shopping = true
	visible = true
	
	legal = is_legal
	shop_inventory_data = inv_data
	
	_clear_selected_item()
	_populate_grid(shop_inventory_data)
	
	if legal:
		print("ShopUI: Displaying Legal Stock")
	else:
		print("ShopUI: Displaying Black Market Stock")

#func _handle_shop_ui(legal_shop: bool):
	## Toggle visibility based on GameState
	#GameState.shopping = not GameState.shopping
	#visible = GameState.shopping
	#
	#if not visible:
		#buyback_ui.hide()
		#EventBus.shop_closed.emit()
		#return
	#
	#legal = legal_shop
	#_clear_selected_item()
	#
	## Determine Inventory Source
	#if legal:
		#print("Opening Commissary (Legal)")
		#if shop_inventory_data != legal_shop_inventory:
			#shop_inventory_data = legal_shop_inventory
			#_refresh_stock(legal_shop_inventory, legal_inventory_pool)
	#else:
		#print("Opening Black Market (Illegal)")
		#if shop_inventory_data != illegal_shop_inventory:
			#shop_inventory_data = illegal_shop_inventory
			#_refresh_stock(illegal_shop_inventory, illegal_inventory_pool)
	#
	#_populate_grid(shop_inventory_data)

func _refresh_stock(shop_inv: InventoryData, pool: InventoryData):
	# Fill empty slots in the persistent shop inventory with new random items
	for i in range(shop_inv.slots.size()):
		if shop_inv.slots[i] == null:
			var picked = _pick_random_stock(pool)
			if picked:
				var new_slot = SlotData.new()
				new_slot.item_data = picked.item_data
				new_slot.quantity = picked.quantity
				shop_inv.slots[i] = new_slot

func _pick_random_stock(pool: InventoryData) -> SlotData:
	if not pool or pool.slots.is_empty(): return null
	# Filter out nulls
	var valid_slots = pool.slots.filter(func(s): return s != null)
	if valid_slots.is_empty(): return null
	return valid_slots.pick_random()

func _populate_grid(inv: InventoryData):
	for child in slot_container.get_children():
		child.queue_free()
	
	for slot_data in inv.slots:
		var slot_ui = SHOP_SLOT_UI.instantiate()
		slot_container.add_child(slot_ui)
		slot_ui.parent_inventory = inv # Important for interaction
		if slot_data:
			slot_ui.set_slot_data(slot_data)

func _clear_selected_item():
	selected_slot = null
	shop_item_context_ui.hide()
	buy_qty_slider.hide()
	buy_qty.hide()

func _on_item_select(slot_data: SlotData):
	if not visible: return
	
	# Verify this slot belongs to the shop
	if not shop_inventory_data.slots.has(slot_data):
		_clear_selected_item()
		return
		
	selected_slot = slot_data
	shop_item_context_ui.show()
	
	shop_item_name.text = slot_data.item_data.name
	shop_item_descript.text = slot_data.item_data.description
	
	# Setup Buying Slider
	var price = slot_data.item_data.buy_value
	var can_afford = floor(GameState.money / max(1, price))
	
	buy_qty_slider.min_value = 1
	buy_qty_slider.max_value = min(slot_data.quantity, can_afford)
	buy_qty_slider.value = 1
	
	if not slot_data.item_data.stackable:
		buy_qty_slider.hide()
	else:
		buy_qty_slider.show()
	
	_update_price_display()

func _update_price_display():
	if not selected_slot: return
	var qty = int(buy_qty_slider.value)
	var cost = selected_slot.item_data.buy_value * qty
	
	shop_item_value.text = "Buy %s: $%s" % [qty, cost]
	shop_item_value.modulate = Color.RED if cost > GameState.money else Color.WHITE

func _on_buy_button_pressed():
	if not selected_slot: return
	var qty = int(buy_qty_slider.value)
	var cost = selected_slot.item_data.buy_value * qty
	
	if GameState.money >= cost:
		GameState.money -= cost
		EventBus.money_updated.emit(GameState.money)
		
		# Add to player
		EventBus.adding_item.emit(selected_slot.item_data, qty)
		
		# Remove from shop
		selected_slot.quantity -= qty
		if selected_slot.quantity <= 0:
			var idx = shop_inventory_data.slots.find(selected_slot)
			shop_inventory_data.slots[idx] = null
			_clear_selected_item()
		
		_populate_grid(shop_inventory_data) # Refresh UI

# --- SELLING ---

func _sell_item(sell_slot: SlotData):
	if not visible: return
	
	# Logic: Player clicks 'Sell' on their own item context menu
	var value = sell_slot.item_data.sell_value * sell_slot.quantity
	
	# Add to buyback (simulating the vendor taking it)
	if legal:
		legal_buyback_slot = sell_slot
	else:
		illegal_buyback_slot = sell_slot
	
	_update_buyback_ui(sell_slot)
	
	GameState.money += value
	EventBus.money_updated.emit(GameState.money)
	
	# Remove from player
	EventBus.removing_item.emit(sell_slot.item_data, sell_slot.quantity, sell_slot)

func _update_buyback_ui(slot: SlotData):
	buyback_ui.show()
	buyback_item_texture.texture = slot.item_data.texture
	buyback_quantity.text = str(slot.quantity)
	buyback_price_label.text = "$%s" % (slot.item_data.sell_value * slot.quantity)

func _on_buyback_button_pressed():
	var slot = legal_buyback_slot if legal else illegal_buyback_slot
	if not slot: return
	
	var cost = slot.item_data.sell_value * slot.quantity
	if GameState.money >= cost:
		GameState.money -= cost
		EventBus.money_updated.emit(GameState.money)
		EventBus.adding_item.emit(slot.item_data, slot.quantity)
		
		if legal: legal_buyback_slot = null
		else: illegal_buyback_slot = null
		
		buyback_ui.hide()

func _on_close_shop_button_pressed():
	GameState.shopping = false
	visible = false
	buyback_ui.hide()
	EventBus.shop_closed.emit()
