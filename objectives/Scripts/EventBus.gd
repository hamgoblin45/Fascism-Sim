extends Node



signal assign_objective(objective: ObjectiveData)
signal advance_objective(objective: ObjectiveData, current_step: ObjectiveStepData)
signal complete_objective(objective: ObjectiveData)
signal remove_objective(objective: ObjectiveData)
