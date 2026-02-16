extends Interactable
class_name HidingSpot

@export var spot_id: String = ""
# 0.0 (obvious) - 1.0 (invisible)
# This is the base change the guards will FAIL to find occupant
@export var concealment_score: float = 0.5

var occupant: NPC = null

func _ready() -> void:
	EventBus.item_interacted.connect(_on_interact)

func _on_interact(object, type, engaged):
	if not engaged or object != self: return
	
	if type == "interact":
		if occupant:
			# If someone is inside, tell them to come out
			_extract_occupant()
		elif GameState.leading_npc: # I might wanna make this a select and toggle rather than them following me 
			#(Interact w/ spot has me select a guest and tell them "Get in there!"
			_assign_occupant(GameState.leading_npc)

func _assign_occupant(npc: NPC):
	occupant = npc
	occupant.hide() # Hides the NPC's model
	occupant.process_mode = Node.PROCESS_MODE_DISABLED # Stop all AI/Physics
	print("HidingSPot: %s is now hiding in %s" % [npc.npc_data.name, name])
	GameState.leading_npc = null # Stop leading (if that's how we do it)

func _extract_occupant():
	if occupant:
		occupant.show()
		occupant.process_mode = Node.PROCESS_MODE_INHERIT
		occupant.global_position = global_position + Vector3.FORWARD # "Step" out
		occupant = null
