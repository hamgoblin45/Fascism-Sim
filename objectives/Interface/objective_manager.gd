extends Node



func _ready() -> void:
	EventBus.assign_objective.connect(_assign_objective)
	EventBus.advance_objective.connect(_advance_objective)
	EventBus.complete_objective.connect(_complete_objective)
	EventBus.remove_objective.connect(_remove_objective)

func _assign_objective(objective: ObjectiveData):
	print("Assign objective %s received by ObjectiveManager" % objective)
	# Check if objective is already assigned, completed, or failed
	for obj in GameState.objectives:
		if obj.id == objective.id:
			print("Objective already exists in GameState")
			return
	
	objective.set_data()
	
	GameState.objectives.append(objective) # Add to GameState to be saved
	
	

func _advance_objective(objective: ObjectiveData):
	print("Advancing objective %s received by ObjectiveManager" % objective)
	for obj in GameState.objectives:
		if obj.id == objective.id:
			print("Objective match found for advance_objective in ObjectiveManager")
			obj.advance_objective()


func _complete_objective(objective: ObjectiveData):
	pass
	

func _remove_objective(objective: ObjectiveData):
	pass
