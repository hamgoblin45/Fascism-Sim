extends PanelContainer

@export var step_data: ObjectiveStepData

@onready var step_label: RichTextLabel = %StepLabel
@onready var step_progress_label: RichTextLabel = %StepProgressLabel


func set_step_data(step: ObjectiveStepData):
	print("Setting step data in objective_step_ui")
	step_data = step
	step_label.text = step.text
	
	if step is ObjectiveStepGatherData:
		step_progress_label.text = ""
