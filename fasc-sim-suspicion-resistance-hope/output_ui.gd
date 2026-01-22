extends PanelContainer

const OUTPUT_LABEL = preload("uid://d4f7fxy2s7ntw")

@onready var output_container: VBoxContainer = $OutputContainer



func _ready():
	EventBus.output.connect(_receive_output)

func _receive_output(text: String):
	var output_instance = OUTPUT_LABEL.instantiate()
	output_container.add_child(output_instance)
	output_instance.set_output(text)
	_check_for_overflow()


func _check_for_overflow():
	var outputs = output_container.get_children()
	if outputs.size() > 12:
		print("Removing oldest output")
		outputs[0].queue_free()
