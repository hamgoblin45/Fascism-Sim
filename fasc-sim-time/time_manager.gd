extends Node
# Handles the logic involved in controlling game time

var time_rate: float = 0.0003

func _ready() -> void:
	handle_time()

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
		#next_day()
		GameState.cycle_time = 0.0
		print("midnight reached")
		EventBus.change_day.emit(GameState.day + 1)


func _on_timer_timeout() -> void:
	GameState.cycle_time += time_rate * GameState.time_speed
	handle_time()

func handle_lights():
	if GameState.time >= 17.5 or GameState.time < 6.0:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_on()
	else:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_off()
