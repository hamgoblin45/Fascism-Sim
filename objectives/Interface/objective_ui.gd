extends PanelContainer
## Just control UI, logic should be handled in the ObjectiveManager

const OBJECTIVE_STEP_UI = preload("uid://btcdsfmx1knfj")

@export var objective_data: ObjectiveData

@onready var objective_name: Label = %ObjectiveName
@onready var objective_description: RichTextLabel = %ObjectiveDescription

@onready var steps_container: VBoxContainer = %StepsContainer


func set_objective_data(objective: ObjectiveData):
	print("Setting objective data via ObjectiveUI")
	# clear out any potential lingering steps
	for child in steps_container.get_children():
		child.queue_free()
	
	objective_data = objective
	
	# Set UI
	objective_name.text = objective.name
	objective_description.text = objective.description
	
	EventBus.objective_advanced.connect(_on_step_advanced)

func _set_current_step(step: ObjectiveStepData):
	print("Setting current step via ObjectiveUI")
	var new_step_ui = OBJECTIVE_STEP_UI.instantiate()
	steps_container.add_child(new_step_ui)
	new_step_ui.set_step_data(step)
	# set step ui in its own code

func _on_step_advanced(objective: ObjectiveData):
	print("step advance acknowledged in objective_ui. Objective: %s, Current Step: %s" % [objective, objective.current_step])
	
	_set_current_step(objective_data.current_step)
	
