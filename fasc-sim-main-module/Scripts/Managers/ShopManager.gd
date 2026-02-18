extends Node

# Key: Merchant ID (String), Value: InventoryData (The generated stock for today)
var daily_shop_cache: Dictionary = {}

func _ready() -> void:
	EventBus.day_changed.connect(_on_day_changed)

func _on_day_changed() -> void:
	print("ShopManager: New day, clearing shop cache.")
	daily_shop_cache.clear()

# Called by MerchantNPC
func get_shop_inventory(merchant_id: String, stock_config: Dictionary) -> InventoryData:
	# 1. Check if we already generated stock for this guy today
	if daily_shop_cache.has(merchant_id):
		return daily_shop_cache[merchant_id]
	
	# 2. If not, generate new stock
	print("ShopManager: Generating fresh stock for %s" % merchant_id)
	var new_stock = _generate_daily_stock(stock_config)
	daily_shop_cache[merchant_id] = new_stock
	return new_stock

func _generate_daily_stock(config: Dictionary) -> InventoryData:
	var shop_inv = InventoryData.new()
	shop_inv.slots.resize(20) # Set size of shop window (e.g. 20 slots)
	
	var current_slot_index = 0
	
	# A. Add Guaranteed Items (Always in stock)
	if config.has("guaranteed") and config["guaranteed"] is Array:
		for item in config["guaranteed"]:
			if current_slot_index >= shop_inv.slots.size(): break
			
			var slot = SlotData.new()
			slot.item_data = item
			slot.quantity = 5 # Default quantity for staples? Or randomize
			shop_inv.slots[current_slot_index] = slot
			current_slot_index += 1

	# B. Fill Random Slots from Pool
	if config.has("pool") and config["pool"] is InventoryData:
		var pool: InventoryData = config["pool"]
		
		# Collect all valid items from pool to create a weighted deck
		# If "Apple" is in the pool 3 times, it's 3x more likely to be picked
		var valid_pool_items: Array[SlotData] = []
		for s in pool.slots:
			if s and s.item_data:
				valid_pool_items.append(s)
		
		if valid_pool_items.is_empty():
			return shop_inv
			
		# Determine how many random items to add (e.g., fill 5 to 10 slots)
		var slots_to_fill = randi_range(5, 12)
		
		for i in range(slots_to_fill):
			if current_slot_index >= shop_inv.slots.size(): break
			
			var picked_slot = valid_pool_items.pick_random()
			
			# Create new instance for shop so we don't edit the pool
			var new_slot = SlotData.new()
			new_slot.item_data = picked_slot.item_data
			# Randomize quantity slightly based on pool definition?
			new_slot.quantity = randi_range(1, picked_slot.quantity) 
			
			shop_inv.slots[current_slot_index] = new_slot
			current_slot_index += 1
			
	return shop_inv
