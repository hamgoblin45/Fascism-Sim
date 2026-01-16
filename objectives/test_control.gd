extends Control

const TEST_GATHER_OBJECTIVE = preload("uid://6fxmo62vnuo4")
const TEST_SIMPLE_OBJECTIVE = preload("uid://dkfaqm5wac657")
const TEST_CHOICE_OBJECTIVE = preload("uid://5qxnfyfegl6t")

const TEST_REQUIRED_ITEM = preload("uid://bd1e65ouafft3")
const TEST_UNRELATED_ITEM = preload("uid://dabk6755bi4j")


## -- BUTTONS
@onready var assign_simple_objective: Button = %AssignSimpleObjective
@onready var advance_simple_objective: Button = %AdvanceSimpleObjective
@onready var fail_simple_objective: Button = %FailSimpleObjective
@onready var turn_in_simple_objective: Button = %TurnInSimpleObjective

@onready var assign_gather_objective: Button = %AssignGatherObjective
@onready var gather_required_item: Button = %GatherRequiredItem
@onready var gather_unrelated_item: Button = %GatherUnrelatedItem
@onready var drop_required_item: Button = %DropRequiredItem

@onready var assign_multi_choice_objective: Button = %AssignMultiChoiceObjective
@onready var choice_1_button: Button = %Choice1Button
@onready var choice_2_button: Button = %Choice2Button

@onready var assign_complex_button: Button = %AssignComplexButton

@onready var output_control: Control = %OutputControl
@onready var output_container: VBoxContainer = %OutputContainer

var outputs: Array[Label]



func _ready():
	EventBus.objective_completed.connect(_on_objective_completed)


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
	
	if !obj.complete:
		EventBus.advance_objective.emit(obj)
		advance_simple_objective.disabled = true
		_print_output("Simple objective advanced. Marking complete since there was only one task")
	

func _on_fail_simple_objective_pressed() -> void:
	fail_simple_objective.disabled = true
	advance_simple_objective.disabled = true


func _on_assign_gather_objective_pressed() -> void:
	assign_gather_objective.disabled = true
	gather_required_item.disabled = false
	gather_unrelated_item.disabled = false
	
	var obj = TEST_GATHER_OBJECTIVE
	EventBus.assign_objective.emit(obj)
	
	print("Assigned gather objective. Data: %s
	Name: %s - Description: %s" % [obj, obj.name, obj.description])
	_print_output("Gather objective assigned")


func _on_gather_required_item_pressed() -> void:
	var req_item = TEST_REQUIRED_ITEM
	# Checks if player already has some and increases quantity if so
	for slot_data in GameState.inventory.slot_datas:
		if slot_data and slot_data.item_data and slot_data.item_data.id == req_item.id:
			slot_data.quantity += 1
			print("Adding one more req_item to inventory")
			_print_output("Found %s in inventory, increasing quantity to %s" % [slot_data.item_data.name, slot_data.quantity])
			EventBus.inventory_item_updated.emit(slot_data) # Simplified version of how it works in Inventory project
			return
	
	var new_slot = InventorySlotData.new()
	new_slot.item_data = req_item
	print("Created a slot to add req-item")
	GameState.inventory.slot_datas.append(new_slot) # This would normally be done by signals in full Inv system, just for testing objectives
	EventBus.inventory_item_updated.emit(new_slot)
	_print_output("Adding %s to inventory" % new_slot.item_data.name)


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
	turn_in_simple_objective.disabled = true
	

func _on_objective_completed(obj: ObjectiveData):
	if obj.id == TEST_SIMPLE_OBJECTIVE.id:
		turn_in_simple_objective.disabled = false
		
	var text = "OBJECTIVE '%s' COMPLETED! Ready to turn in" % obj.name
	_print_output(text)


func _on_assign_multi_choice_objective_pressed() -> void:
	assign_multi_choice_objective.disabled = true
	
	choice_1_button.disabled = false
	choice_2_button.disabled = false
	
	var obj = TEST_CHOICE_OBJECTIVE
	EventBus.assign_objective.emit(obj)
	
	print("Assigned multi-choice objective. Data: %s
	Name: %s - Description: %s" % [obj, obj.name, obj.description])
	_print_output("Multi-choice objective assigned")
	
	


func _on_choice_1_button_pressed() -> void:
	pass # Replace with function body.


func _on_choice_2_button_pressed() -> void:
	pass # Replace with function body.
