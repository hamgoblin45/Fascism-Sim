extends Control

@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_value: Label = %HPValue
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_value: Label = %EnergyValue
# Testing vars
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var hunger_value: Label = %HungerValue


func _ready():
	EventBus.main_scene_loaded.emit() # This will actually be done in the main game scene instead of here, testing only
	EventBus.stat_changed.connect(_change_stat)
	
	
	
	_set_hud()


func _set_hud():
	hp_bar.max_value = GameState.max_hp
	hp_bar.value = GameState.hp
	hp_value.text = "%s/%s" % [str(snapped(GameState.hp, 1)), str(snapped(GameState.max_hp, 1))]
	
	energy_bar.max_value = GameState.max_energy
	energy_bar.value = GameState.energy
	energy_value.text = str(snapped(GameState.energy,1))
	
	# This is only for testing unless we decide to display Hunger to player
	hunger_bar.value = GameState.hunger
	hunger_value.text = str(snapped(GameState.hunger, 1))


# Should this go in a PlayerManager, stay here, or something else?
func _change_stat(_stat: String, _value: float):
	_set_hud()
