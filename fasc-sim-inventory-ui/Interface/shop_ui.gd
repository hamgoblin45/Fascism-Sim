extends PanelContainer

const SHOP_SLOT_UI = preload("uid://cj1cyf80hrqb4")

#Create a "Pool" of loot for the inventory to pull from
@export var legal_inventory_pool: InventoryData
@export var illegal_inventory_pool: InventoryData
@export var legal_shop_inventory: InventoryData
@export var illegal_shop_inventory: InventoryData

@onready var slot_container: GridContainer = %BuySlotContainer

var legal: bool = true


func _ready():
	EventBus.shopping.connect(_handle_shop_ui)
	EventBus.inventory_interacted.connect(_on_inventory_interact)

func _handle_shop_ui(legal: bool):
	GameState.shopping = not GameState.shopping
	visible = GameState.shopping
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
			var selected_item = legal_inventory_pool.slot_datas.pick_random().item_data
			var new_slot = InventorySlotData.new()
			new_slot.item_data = selected_item
	_populate_shop(legal_shop_inventory)

func _set_illegal_inventory():
	# Checks how much room in the shop inventory isn't already taken by persistant stock
	for slot in illegal_shop_inventory.slot_datas:
		if slot == null:
			var selected_item = illegal_inventory_pool.slot_datas.pick_random().item_data
			var new_slot = InventorySlotData.new()
			new_slot.item_data = selected_item
	_populate_shop(illegal_shop_inventory)

func _populate_shop(inv: InventoryData):
	for slot_data in inv.slot_datas:
		var new_slot_ui = SHOP_SLOT_UI.instantiate()
		var new_slot_data = InventorySlotData.new()
		new_slot_data.item_data = slot_data.item_data
		new_slot_data.quantity = slot_data.quantity
		new_slot_ui.parent_inventory = inv
		new_slot_ui.set_slot_data(new_slot_data)
		slot_container.add_child(new_slot_ui)

func _on_inventory_interact(inv: InventoryData, panel: PanelContainer, slot_data: InventorySlotData, interact_type: String):
	if legal and inv != legal_shop_inventory:
		return
	elif not legal and inv != illegal_shop_inventory:
		return
	
	
