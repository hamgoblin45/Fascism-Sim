extends Node



func _ready() -> void:
	EventBus.assign_objective.connect(_assign_objective)

func _assign_objective(objective: ObjectiveData):
	print("Assign objective %s received by ObjectiveManager" % objective)
