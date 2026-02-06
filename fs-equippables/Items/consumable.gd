extends Node3D
@export var item_data: InventoryItemData

var swing_power: float = 0.0
var power_max: float = 20.0
var power_build_tick: float = 2.5


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("click") and GameState.equipped_item == item_data:
		_handle_hold_click(delta)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_released("click") and swing_power > 0:
		_on_release()

func _handle_hold_click(delta: float):
	if swing_power < power_max:
		swing_power += power_build_tick * delta

func _on_release():
	print("SWINGING with a swing power of ", swing_power)
