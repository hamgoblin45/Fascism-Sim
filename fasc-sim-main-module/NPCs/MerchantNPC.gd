extends NPC
class_name MerchantNPC

@export_category("Merchant Settings")
@export var merchant_id: String = "black_market_1" # Must be unique per merchant
@export var is_legal_merchant: bool = false

# The "Deck of Cards" to draw random items from.
# Add items multiple times to increase their drop weight.
@export var inventory_pool: InventoryData 

# Items that will ALWAYS appear (e.g., Bread for a baker)
@export var guaranteed_items: Array[ItemData] 

func _ready():
	super._ready()
	Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument: String):
	if argument == "open_shop" and GameState.talking_to == self:
		open_shop()

# Hook this function to a Dialogic Signal event called "open_shop"
func open_shop():
	print("MerchantNPC: Requesting stock from ShopManager...")
	
	var config = {
		"pool": inventory_pool,
		"guaranteed": guaranteed_items
	}
	
	# Get today's stock (persists until day change)
	var daily_stock = ShopManager.get_shop_inventory(merchant_id, config)
	
	# Tell EventBus to open UI with this specific data
	EventBus.open_specific_shop.emit(daily_stock, is_legal_merchant)

func _on_interact(object, type, engaged):
	super._on_interact(object, type, engaged)
