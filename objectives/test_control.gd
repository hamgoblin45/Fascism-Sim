extends Control

## -- BUTTONS
@onready var assign_simple_objective: Button = $ButtonsPanel/VBoxContainer/AssignSimpleObjective
@onready var advance_simple_objective: Button = $ButtonsPanel/VBoxContainer/AdvanceSimpleObjective
@onready var fail_simple_objective: Button = $ButtonsPanel/VBoxContainer/FailSimpleObjective
@onready var assign_gather_objective: Button = $ButtonsPanel/VBoxContainer/AssignGatherObjective
@onready var gather_required_item: Button = $ButtonsPanel/VBoxContainer/GatherRequiredItem
@onready var gather_unrelated_item: Button = $ButtonsPanel/VBoxContainer/GatherUnrelatedItem
@onready var drop_required_item: Button = $ButtonsPanel/VBoxContainer/DropRequiredItem



func _on_assign_simple_objective_pressed() -> void:
	assign_simple_objective.disabled = true
	advance_simple_objective.disabled = false
	fail_simple_objective.disabled = false


func _on_advance_simple_objective_pressed() -> void:
	pass # Replace with function body.


func _on_fail_simple_objective_pressed() -> void:
	fail_simple_objective.disabled = true


func _on_assign_gather_objective_pressed() -> void:
	assign_gather_objective.disabled = true


func _on_gather_required_item_pressed() -> void:
	pass # Replace with function body.


func _on_gather_unrelated_item_pressed() -> void:
	pass # Replace with function body.


func _on_drop_required_item_pressed() -> void:
	pass # Replace with function body.
