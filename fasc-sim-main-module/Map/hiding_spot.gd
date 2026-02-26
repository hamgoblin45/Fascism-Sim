extends Interactable
class_name HidingSpot

@export var spot_id: String = ""
# 0.0 (obvious) - 1.0 (invisible)
# This is the base chance the guards will FAIL to find occupant
@export var concealment_score: float = 0.5

var occupant: NPC = null
var reserved_by: NPC = null # NEW: Tracks who is currently running to this spot

func _ready() -> void:
	EventBus.item_interacted.connect(_on_interact)

func _on_interact(object, type, engaged):
	if not engaged or object != self: return
	
	if type == "interact":
		if occupant:
			_extract_occupant()
		elif not reserved_by:
			_request_hide_guest()

func _request_hide_guest():
	var available_guests = []
	for guest in GuestManager.active_guests:
		if not guest.is_hidden and guest.target_hiding_spot == null:
			available_guests.append(guest)
			
	if available_guests.is_empty():
		print("HidingSpot: No free guests to hide here.")
		return
		
	if available_guests.size() == 1:
		# Only one guest? Tell them to run here immediately!
		available_guests[0].command_go_hide(self)
	else:
		# Multiple guests? Tell the UI to open a selection menu!
		print("HidingSpot: Multiple guests found. Opening Selection Menu.")
		EventBus.open_guest_selection_menu.emit(self, available_guests)

func _assign_occupant(npc: NPC):
	occupant = npc
	reserved_by = null
	occupant.hide() 
	occupant.process_mode = Node.PROCESS_MODE_DISABLED 
	occupant.global_position = global_position # Snap them perfectly inside
	print("HidingSpot: %s is now hiding in %s" % [npc.npc_data.name, name])

func _extract_occupant():
	if occupant:
		occupant.show()
		occupant.process_mode = Node.PROCESS_MODE_INHERIT
		occupant.global_position = global_position + (global_transform.basis.z * 1.5) # Step out forward
		
		# Give them a new idle command so they don't just freeze
		GuestManager.send_to_random_spot(occupant)
		occupant = null
