extends Node

var prev_status_check: float = 0.0
var prev_hunger_check: float = 0.0

func _ready():
	
	# Start everything at max
	GameState.hp = GameState.max_hp
	GameState.energy = GameState.max_energy
	GameState.hunger = 0
	
	var total_minutes: float = (GameState.hour * 24) + GameState.minute
	prev_status_check = total_minutes
	prev_hunger_check = total_minutes

	EventBus.change_stat.connect(_change_stat)
	

func _change_stat(stat: String, value: float):
	#print("Changing %s by %s" % [stat, value])
	match stat:
		"hp":
			GameState.hp += value
			if GameState.hp > GameState.max_hp:
				GameState.hp = GameState.max_hp
			if GameState.hp <= 0:
				GameState.hp = 0
				print("You are fucking dead")
			#print("New HP value: %s" % str(GameState.hp))
		"energy":
			
			GameState.energy += value
			if GameState.energy > GameState.max_energy:
				GameState.energy = GameState.max_energy
			if GameState.energy <= 0:
				GameState.energy = 0
				print("You ran out of energy")
			#print("New energy value: %s" % str(GameState.energy))
		"hunger":
			GameState.hunger += value
			if GameState.hunger <= 0:
				GameState.hunger = 0
			
			if GameState.hunger < 25:
				GameState.hunger_level = 1
			elif GameState.hunger < 50:
				GameState.hunger_level = 2
			elif GameState.hunger < 75:
				GameState.hunger_level = 3
			else:
				GameState.hunger_level = 4
			
			if GameState.hunger > GameState.max_hunger:
				GameState.hunger = GameState.max_hunger
			
				print("You are starving to death")
			#print("New Hunger value: %s, now at Hunger Level %s" % [str(GameState.hunger), str(GameState.hunger_level)])
		
	
	EventBus.stat_changed.emit(stat)


func _on_status_check_timer_timeout() -> void:
	var total_minutes: float = (GameState.hour * 60) + GameState.minute
	print("There have been %s minutes in the day so far.
	Prev hunger check: %s ago. Prev status check %s ago" % [str(total_minutes), str(total_minutes - prev_hunger_check), str(total_minutes - prev_status_check)])
	
	# Check for times past midnight
	if prev_status_check - total_minutes > 1000:
		prev_status_check = 1440 - prev_status_check
	if prev_hunger_check - total_minutes > 1000:
		prev_hunger_check = 1440 - prev_hunger_check
		
	# Change hunger every 60 min
	if total_minutes - prev_hunger_check >= 60:
		print("It's been an hour since last hunger check!")
		prev_hunger_check = total_minutes
		_change_stat("hunger", GameState.hunger_drain_rate)
	
	# Only updates for every in-game minute regardless of time rate
	if total_minutes - prev_status_check < 1.0:
		return
	
	prev_status_check = total_minutes
	
	var energy_change = -GameState.energy_drain_rate * GameState.hunger_level
	if GameState.working:
		energy_change *= 3
	
	_change_stat("energy", energy_change)
	
	if GameState.hunger >= 100:
		_change_stat("hp", -GameState.hp_starve_drain_rate)
	
	
