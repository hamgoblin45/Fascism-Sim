extends PanelContainer
## Just control UI, logic should be handled in the ObjectiveManager

const OBJECTIVE_STEP_UI = preload("uid://btcdsfmx1knfj")

@export var objective_data: ObjectiveData

@onready var steps_container: VBoxContainer = %StepsContainer




func _set_current_step(step: ObjectiveStepData):
	var new_step_ui = OBJECTIVE_STEP_UI.instantiate()
	steps_container.add_child(new_step_ui)
	new_step_ui.set_step_data(step)
	# set step ui in its own code

func _on_step_advanced(completed_step: ObjectiveStepData, next_step: ObjectiveStepData):
	print("step advance acknowledged in objective_ui. Step: %s" % completed_step)
	
	_set_current_step(next_step)
	
