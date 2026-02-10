extends Interactable
class_name GuestClue

@export var suspicion_contribution: float = 5.0 # How much this clue increases search intensity

func _on_interact(_obj, _type, engaged):
	if not engaged: return
	print("Player cleaning up clue of having a guest")
	queue_free()
