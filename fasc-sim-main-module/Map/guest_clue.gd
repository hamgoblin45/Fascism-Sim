extends Interactable
class_name GuestClue

@export_group("Suspicion Settings")
@export var suspicion_contribution: float = 15.0 # How much this clue increases search intensity
@export var investigation_time: float = 3.0 # How long the officer looks at it
@export var bark_line: String = "What's this?"

var is_discovered: bool = false

func _ready() -> void:
	super._ready() # Run Interactable's _ready()
	add_to_group("clues")

func _on_interact(_obj, _type, engaged):
	if not engaged: return
	print("Player cleaning up clue of having a guest")
	# Come up with a mechanic for attempting to clean mid raid while officer looking at it
	remove_from_group("clues")
	queue_free()

func on_spotted(officer: NPC):
	if is_discovered: return
	is_discovered = true
	
	print ("Clue spotted by officer")
	
	officer.spawn_bark(bark_line)
	officer.look_at_target(self)
	
	SearchManager.clue_discovered(self)
