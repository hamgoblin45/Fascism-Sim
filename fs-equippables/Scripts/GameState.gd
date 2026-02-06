extends Node

## -- Time
var day: int = 1
var hour: int = 8
var minute: int = 0


## -- Interface
var ui_open: bool = false
var in_dialogue: bool = false
var shopping: bool = false # Dictates how inventory UI will react, primarily Using an item vs Selling it
var money: float = 100
var pockets_inventory: InventoryData
var active_hotbar_index: int = -1
var equipped_item: InventoryItemData

## -- Player / 3D Controller
var player: CharacterBody3D
var held_item

## -- Status
var hp: float = 100.0
var max_hp: float = 100.0

var max_energy: float = 100.0
var energy: float = 100.0: # Only refills on a new day / eating
	set(value):
		energy = clamp(value, 0 , max_energy)
		if stamina > energy:
			stamina = energy
var energy_drain_rate: float = 0.05 # How fast energy drains over time

var stamina: float = 100.0:
	set(value):
		stamina = clamp(value, 0, energy)
var stamina_regen_rate: float = 15.0

var hunger: float = 0.0
var max_hunger: float = 100.0
var hunger_level: int = 0
var hunger_drain_rate: float = 0.05 # How quickly you get hungry
var hp_starve_drain_rate: float = 0.05 # How much dmg you take when starving

var working: bool = false

func _process(delta: float) -> void:
	if stamina < energy:
		stamina += stamina_regen_rate * delta
