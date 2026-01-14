extends PanelContainer
# Only handle UI stuff here! Logic goes in TimeManager

@onready var weekday_label: Label = %WeekdayLabel
@onready var day_label: Label = %DayLabel
@onready var time_label: Label = %TimeLabel
@onready var speed_label: Label = %SpeedLabel
@onready var speed_slider: HSlider = %SpeedSlider

var paused: bool = false

func _ready():
	EventBus.main_scene_loaded.connect(_set_ui)
	EventBus.change_day.connect(_set_day)
	#EventBus.day_changed.connect(_set_day)
	EventBus.minute_changed.connect(_set_time)
	EventBus.day_changed.connect(_day_changed)

func _set_ui():
	_set_day(GameState.day)
	_set_time(GameState.hour, GameState.minute)
	speed_label.text = str(GameState.time_speed)


func _set_day(day: int):
	weekday_label.text = GameState.weekday
	day_label.text = "Day %s" % day

func _set_time(hour: int, minute: int):
	# Format hours
	var formatted_hour: String = ""
	if hour < 10:
		formatted_hour = "0%s" % str(hour)
	else:
		formatted_hour = str(hour)
	
	# Format minutes
	var formatted_min: String = ""
	if minute < 10:
		formatted_min = "0%s" % str(minute)
	else:
		formatted_min = str(minute)
	
	var formatted_time = "%s:%s" % [formatted_hour,formatted_min]
	time_label.text = formatted_time


func _on_speed_slider_value_changed(value: float) -> void:
	GameState.time_speed = value
	speed_label.text = str(value)


func _day_changed(_new_day: int):
	%DayChangeLabel.show()
	await get_tree().create_timer(1.5).timeout
	%DayChangeLabel.hide()


func _on_pause_button_pressed() -> void:
	paused = !paused
	EventBus.set_paused.emit(paused)
	
	if paused:
		%PauseButton.text = "RESUME"
	else:
		%PauseButton.text = "PAUSE"
