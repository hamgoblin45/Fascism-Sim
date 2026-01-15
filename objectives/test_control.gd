extends Control

const TEST_GATHER_OBJECTIVE = preload("uid://6fxmo62vnuo4")
const TEST_SIMPLE_OBJECTIVE = preload("uid://5qxnfyfegl6t")

## -- BUTTONS
@onready var assign_simple_objective: Button = $ButtonsPanel/VBoxContainer/AssignSimpleObjective
@onready var advance_simple_objective: Button = $ButtonsPanel/VBoxContainer/AdvanceSimpleObjective
@onready var fail_simple_objective: Button = $ButtonsPanel/VBoxContainer/FailSimpleObjective
@onready var assign_gather_objective: Button = $ButtonsPanel/VBoxContainer/AssignGatherObjective
@onready var gather_required_item: Button = $ButtonsPanel/VBoxContainer/GatherRequiredItem
@onready var gather_unrelated_item: Button = $ButtonsPanel/VBoxContainer/GatherUnrelatedItem
@onready var drop_required_item: Button = $ButtonsPanel/VBoxContainer/DropRequiredItem

@onready var output_control: Control = %OutputControl
@onready var output_container: VBoxContainer = %OutputContainer

var outputs: Array[Label]


func _on_assign_simple_objective_pressed() -> void:
	assign_simple_objective.disabled = true
	advance_simple_objective.disabled = false
	fail_simple_objective.disabled = false
	
	var obj = TEST_SIMPLE_OBJECTIVE
	EventBus.assign_objective.emit(obj)
	
	print("Assigned simple objective. Data: %s
	Name: %s - Description: %s" % [obj, obj.name, obj.description])
	_print_output("Simple objective assigned")



func _on_advance_simple_objective_pressed() -> void:
	var obj = TEST_SIMPLE_OBJECTIVE
	EventBus.advance_objective.emit(obj)


func _on_fail_simple_objective_pressed() -> void:
	fail_simple_objective.disabled = true
	advance_simple_objective.disabled = true


func _on_assign_gather_objective_pressed() -> void:
	assign_gather_objective.disabled = true


func _on_gather_required_item_pressed() -> void:
	pass # Replace with function body.


func _on_gather_unrelated_item_pressed() -> void:
	pass # Replace with function body.


func _on_drop_required_item_pressed() -> void:
	pass # Replace with function body.


func _print_output(text: String):
	var new_label = Label.new()
	new_label.text = text
	output_container.add_child(new_label)
	
	if output_container.get_children().size() > 8:
		output_container.get_children()[0].queue_free()


func _on_turn_in_simple_objective_pressed() -> void:
	var obj = TEST_SIMPLE_OBJECTIVE
	EventBus.turn_in_objective.emit(obj)
