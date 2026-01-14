extends Node
# Handles the logic involved in controlling game time

var time_rate: float = 0.0003

func _ready() -> void:
	_setup_new_day()
	handle_time()
	
	EventBus.set_paused.connect(_handle_pause)

func handle_time():
	GameState.time = 1440 * GameState.cycle_time / 60
	GameState.hour = floor(GameState.time)
	var minute_fraction = GameState.time - GameState.hour
	GameState.minute = int(60 * minute_fraction)
	
	EventBus.minute_changed.emit(GameState.hour, GameState.minute)
	#print("Hour: %s" % GameState.hour)
	#print("Minute: %s" % GameState.minute)
	#print("It is %s minute" % minute_fraction)
	if GameState.cycle_time >= 1.0:
		_change_day()
		

func _change_day(): # Have this done during day transition
	GameState.cycle_time = 0.0
	GameState.day += 1
	
	_change_weekday()
	
	print("CHANGING DAY TO %s" % GameState.day)
	EventBus.day_changed.emit(GameState.day)
	_setup_new_day() # Have this actually run after loading back in for a new day / upon game start

func _change_weekday():
	match GameState.weekday:
		"Monday":
			GameState.weekday = "Tuesday"
		"Tuesday":
			GameState.weekday = "Wednesday"
		"Wednesday":
			GameState.weekday = "Thursday"
		"Thursday":
			GameState.weekday = "Friday"
		"Friday":
			GameState.weekday = "Saturday"
		"Saturday":
			GameState.weekday = "Sunday"
		"Sunday":
			GameState.weekday = "Monday"

func _setup_new_day():
	GameState.time = 8.0 # in hours
	GameState.cycle_time = GameState.time / 24
	#GameState.cycle_time = 0.33 # between 0.0 and 1.0
	#EventBus.new_day_started.emit()


func _on_timer_timeout() -> void:
	GameState.cycle_time += time_rate * GameState.time_speed
	handle_time()


func _handle_pause(paused: bool):
	get_tree().paused = paused

func handle_lights():
	if GameState.time >= 17.5 or GameState.time < 6.0:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_on()
	else:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_off()
