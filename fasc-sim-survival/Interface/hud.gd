extends Control

@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_value: Label = %HPValue
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_value: Label = %EnergyValue


func _ready():
	EventBus.stat_changed.connect(_change_stat)
	
	GameState.hp = GameState.max_hp
	GameState.energy = GameState.max_energy
	
	_set_hud()


func _set_hud():
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	hp_value.text = "%s/%s" % [str(snapped(GameState.hp, 1)), str(snapped(GameState.max_hp, 1))]
	
	energy_bar.max_value = GameState.max_energy
	energy_bar.value = GameState.energy
	energy_value.text = str(snapped(GameState.energy,1))


# Should this go in a PlayerManager, stay here, or something else?
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
	
	_set_hud()
