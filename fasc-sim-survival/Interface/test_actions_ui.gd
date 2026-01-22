extends PanelContainer

@onready var eat_something: Button = %EatSomething
@onready var take_dmg: Button = %TakeDmg
@onready var hold_to_work: Button = %HoldToWork


func _on_eat_something_pressed() -> void:
	print("Eating something")
	# These values will all be set in the ConsumableData that is used and will be emitted upon consumption
	EventBus.change_stat.emit("hp", 1.0)
	EventBus.change_stat.emit("energy", 10.0)
	EventBus.change_stat.emit("hunger", -10.0)


func _on_take_dmg_pressed() -> void:
	EventBus.change_stat.emit("hp", -5)


func _on_hold_to_work_button_down() -> void:
	GameState.working = true


func _on_hold_to_work_button_up() -> void:
	GameState.working = false
