extends Control

const LADY = preload("uid://dlqp1w41fktkf")
const GRUNT = preload("uid://cbxe2cpbaau0c")



var selected_npc: NPCData

@onready var npc_select: OptionButton = %NPCSelect
@onready var state_select: OptionButton = %StateSelect


func _ready():
	_on_npc_select_item_selected(npc_select.selected)
	_on_state_select_item_selected(state_select.selected)

func _on_npc_select_item_selected(index: int) -> void:
	match index:
		0:
			selected_npc = LADY
		1:
			selected_npc = GRUNT

## EDIT THESE NAMES TO MATCH ANIMS

func _on_take_item_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "TakeItem")


func _on_state_select_item_selected(index: int) -> void:
	match index:
		0:
			EventBus.npc_set_state.emit(selected_npc, "IDLE")
		1:
			EventBus.npc_set_state.emit(selected_npc, "WALK")
		2:
			EventBus.npc_set_state.emit(selected_npc, "TALK")
