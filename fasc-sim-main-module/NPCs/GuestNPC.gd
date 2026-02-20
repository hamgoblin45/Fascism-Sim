extends NPC
class_name GuestNPC

var is_inside_house: bool = false
var is_hidden: bool = false
var current_hiding_spot: HidingSpot = null

# --- NEEDS SYSTEM ---
var hunger: float = 0.0 # 0 is full, 100 is starving
var stress: float = 0.0 # 0 is calm, 100 is panicking

func _ready() -> void:
	super._ready()
	EventBus.giving_item.connect(_on_item_given)

func hide_in_spot(spot: HidingSpot):
	is_hidden = true
	current_hiding_spot = spot
	hide()
	collision_layer = 0
	state = IDLE

func exit_hiding():
	is_hidden = false
	current_hiding_spot = null
	show()
	collision_layer = 1

# --- FEEDING SYSTEM ---
func _on_item_given(slot_data: SlotData):
	# Only accept the item if the player is actively talking to THIS guest
	if GameState.talking_to != self: 
		return
		
	var item = slot_data.item_data
	var helped = false
	
	# Check if the item is consumable
	if item is ConsumableData:
		# Extract values from the effects dictionary safely (defaults to 0.0 if not found)
		# Assuming a positive value means "Amount of Need Relieved" (e.g., {"hunger": 30} removes 30 hunger)
		var nut = item.effects.get("hunger", 0.0)
		var s_rel = item.effects.get("stress", 0.0)
		
		if nut != 0:
			# Clamp keeps it safely between 0 and 100
			hunger = clamp(hunger - nut, 0.0, 100.0) 
			helped = true
		
		if s_rel != 0:
			stress = clamp(stress - s_rel, 0.0, 100.0)
			helped = true
			
	if helped:
		spawn_bark("Thank you, I really needed this.")
		print("GuestNPC: Fed %s. Hunger is now %s. Stress is now %s." % [item.name, hunger, stress])
		# Remove 1 quantity of the item from the player's inventory
		EventBus.removing_item.emit(item, 1, slot_data)
	else:
		spawn_bark("I don't need this right now...")
