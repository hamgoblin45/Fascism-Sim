extends Resource
class_name ObjectiveData
## All EventBus signals emitted from here should start with "objective_" as these are confirming the change to data took place

@export var name: String = ""
@export var id: String = ""
@export var description: String = ""

@export var step_datas: Array[ObjectiveStepData]

var current_step: ObjectiveStepData

@export var turn_in_npc: String = "" # Not sure if this is necessary but putting it here in case
var complete: bool = false
var turned_in: bool = false
var failed: bool = false

@export var follow_up_objective: ObjectiveData


func set_data():
	current_step = step_datas[0] # Assign first step
	EventBus.objective_assigned.emit(self)

func advance_objective():
	if !current_step:
		current_step = step_datas[0]
		return
	
	var next_step_index: int = 0
	for step in step_datas:
		if current_step.id == step.id:
			next_step_index = step_datas.find(step) + 1
			break
	
	if next_step_index >= step_datas.size():
		complete = true
		EventBus.objective_completed.emit(self)
		return
	
	current_step = step_datas[next_step_index]
	EventBus.objective_advanced.emit(self)
