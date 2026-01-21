extends Control

const LADY = preload("uid://dlqp1w41fktkf")
const GRUNT = preload("uid://cbxe2cpbaau0c")



var selected_npc: NPCData

@onready var npc_select: OptionButton = %NPCSelect
@onready var state_select: OptionButton = %StateSelect


func _ready():
	_on_npc_select_item_selected(npc_select.selected)
	#_on_state_select_item_selected(state_select.selected)
	_on_idle_button_pressed()

func _on_npc_select_item_selected(index: int) -> void:
	match index:
		0:
			selected_npc = LADY
		1:
			selected_npc = GRUNT
#
#func _on_state_select_item_selected(index: int) -> void:
	#match index:
		#0:
			#EventBus.npc_set_state.emit(selected_npc, "IDLE")
		#1:
			#EventBus.npc_set_state.emit(selected_npc, "WALK")
		#2:
			#EventBus.npc_set_state.emit(selected_npc, "TALK")


## EDIT THESE NAMES TO MATCH ANIMS

func _on_take_item_button_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "TakeItem")

func _on_give_item_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "GiveItem")

func _on_pull_rifle_out_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "PullRifleOut")

func _on_put_rifle_away_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "PutRifleAway")

func _on_salute_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Salute")

func _on_exclaim_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Exclaim")

func _on_cry_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Cry")

func _on_laugh_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Laugh")

func _on_yes_pressed() -> void:
	EventBus.npc_play_anim.emit(selected_npc, "Yes")


func _on_idle_button_pressed() -> void:
	EventBus.npc_set_state.emit(selected_npc, "IDLE")
	%WalkButton.button_pressed = false
	%TalkButton.button_pressed = false


func _on_walk_button_pressed() -> void:
	EventBus.npc_set_state.emit(selected_npc, "WALK")
	%IdleButton.button_pressed = false
	%TalkButton.button_pressed = false


func _on_talk_button_pressed() -> void:
	EventBus.npc_set_state.emit(selected_npc, "TALK")
	%IdleButton.button_pressed = false
	%WalkButton.button_pressed = false
