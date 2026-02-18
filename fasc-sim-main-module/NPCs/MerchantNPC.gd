extends NPC
class_name MerchantNPC

@export_category("Merchant Settings")
@export var merchant_id: String = "black_market_1"
@export var is_legal_merchant: bool = false
@export var inventory_pool: InventoryData 
@export var guaranteed_items: Array[ItemData] 

var is_trading: bool = false # NEW: Track state locally

func _ready():
	super._ready()
	Dialogic.signal_event.connect(_on_dialogic_signal)
	EventBus.shop_closed.connect(_on_shop_closed)

func open_shop():
	print("MerchantNPC: Requesting stock from ShopManager...")
	is_trading = true # Mark trade as active
	
	var config = { "pool": inventory_pool, "guaranteed": guaranteed_items }
	var daily_stock = ShopManager.get_shop_inventory(merchant_id, config)
	
	EventBus.open_specific_shop.emit(daily_stock, is_legal_merchant)

func _on_dialogic_signal(argument: String):
	if argument == "open_shop" and GameState.talking_to == self:
		open_shop()
	
	if argument == "visitor_leave" and GameState.talking_to == self:
		EventBus.visitor_leave_requested.emit(self)

func _on_shop_closed():
	if is_trading:
		is_trading = false
		print("MerchantNPC: Shop closed, starting closing dialogue.")
		DialogueManager.start_dialogue("merchant_closing", npc_data.name)
