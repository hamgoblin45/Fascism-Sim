extends NPC
class_name GuestNPC

var is_inside_house: bool = false
var is_hidden: bool = false
var current_hiding_spot: HidingSpot = null

# --- NEEDS SYSTEM ---
var hunger: float = 0.0 # 0 is full, 100 is starving
var stress: float = 0.0 # 0 is calm, 100 is panicking

@onready var needs_billboard = $GuestNeedsBillboard
var look_timer: float = 0.0
var is_being_looked_at: bool = false

func _ready() -> void:
	super._ready()
	EventBus.giving_item.connect(_on_item_given)
	if needs_billboard:
		needs_billboard.setup(self)
	EventBus.looking_at_interactable.connect(_on_look_change)

func _process(delta: float) -> void:
	# If we are looking at them, count up to 1 second
	if is_being_looked_at:
		look_timer += delta
		if look_timer >= 1.0 and needs_billboard:
			needs_billboard.reveal()
	else:
		# If we look away, reset timer and hide immediately
		look_timer = 0.0
		if needs_billboard:
			needs_billboard.hide_ui()

func _on_look_change(interactable: Interactable, looking: bool):
	# Check if the interactable we are looking at belongs to THIS specific NPC
	if interactable == interact_area:
		is_being_looked_at = looking

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
