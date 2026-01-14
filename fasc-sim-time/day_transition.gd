extends Control

@onready var new_day_fade: AnimationPlayer = %NewDayFade
@onready var new_day_label: Label = %NewDayLabel


func _ready() -> void:
	EventBus.end_day.connect(_start_day_transition)
	EventBus.day_changed.connect(_show_day_change)

func _start_day_transition():
	print("Start_Day_Transition called on DayTransition")
	EventBus.set_paused.emit(true)
	show()
	new_day_label.text = "DAY %s" % str(GameState.day)
	new_day_fade.play("fade_in")

func _show_day_change():
	new_day_label.text = "DAY %s" % str(GameState.day)

func _on_start_new_day_button_pressed() -> void:
	new_day_fade.play("fade_out")

func _on_new_day_fade_animation_finished(anim_name: StringName) -> void:
	if anim_name == "fade_in":
		EventBus.change_day.emit()
	if anim_name == "fade_out":
		EventBus.start_day.emit()
		hide()
