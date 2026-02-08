extends Node
# Used to call functions across the game from dialogue, especially Objectives and score adjustments (Suspicion, resistance, etc)

# Call this func from Dialogic: DialogueBridge.accept_quest("path to objective")
func accept_objective(path: String):
	var obj = load(path)
	if obj:
		EventBus.advance_objective.emit(obj)

# This is used to confirm player has an objective before show a particular dialogue branch
func is_objective_complete(id: String) -> bool:
	for obj in GameState.objectives:
		if obj.id == id:
			return obj.complete
	return false
