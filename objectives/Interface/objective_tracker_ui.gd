extends PanelContainer


const OBJECTIVE_UI = preload("uid://b4q0h7ka7r6wv")


@onready var objective_container: VBoxContainer = %ObjectiveContainer


func _ready():
	EventBus.assign_objective.connect(_on_objective_assigned)

func _on_objective_assigned(objective: ObjectiveData):
	print("Objective assignment received by ObjectiveTrackerUI")
	var objective_ui = OBJECTIVE_UI.instantiate()
	objective_container.add_child(objective_ui)
	objective_ui.set_objective_data(objective)
