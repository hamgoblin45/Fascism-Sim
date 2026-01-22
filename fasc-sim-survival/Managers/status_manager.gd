extends Node



func _ready():
	
	# Start everything at max
	GameState.hp = GameState.max_hp
	GameState.energy = GameState.max_energy
	GameState.hunger = 0

	EventBus.stat_changed.connect(_change_stat)

func _change_stat(stat: String, value: float):
	match stat:
		"hp":
			GameState.hp += value
			if GameState.hp > GameState.max_hp:
				GameState.hp = GameState.max_hp
			if GameState.hp <= 0:
				GameState.hp = 0
				print("You are fucking dead")
		"energy":
			GameState.energy += value
			if GameState.energy > GameState.max_energy:
				GameState.energy = GameState.max_energy
			if GameState.energy <= 0:
				GameState.energy = 0
				print("You ran out of energy")
		"hunger":
			GameState.hunger =+ value
			if GameState.hunger > GameState.max_hunger:
				GameState.hunger = GameState.max_hunger
			if GameState.hunger <= 0:
				GameState.hunger = 0
				print("You are starving to death")
				
