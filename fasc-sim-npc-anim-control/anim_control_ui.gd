extends Control

const LADY = preload("uid://dlqp1w41fktkf")


var selected_npc: NPCData

@onready var npc_select: OptionButton = %NPCSelect


func _ready():
	_on_npc_select_item_selected(npc_select.selected)

func _on_npc_select_item_selected(index: int) -> void:
	match index:
		0:
			selected_npc = LADY

## EDIT THESE NAMES TO MATCH ANIMS

func _on_idle_1_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Idle1")


func _on_talk_1_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Talk1")


func _on_walk_1_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Walking")


func _on_take_item_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "TakeItem")
