extends Node

## -- STATS
var hp: float = 10.0
var max_hp: float = 20.0
var hp_starve_drain_rate: float = 0.025 # how much HP you lose per minute when starving

var energy: float = 100.0
var max_energy: float = 100.0
var energy_drain_rate: float = 0.1 # % of hunger lost per minute, which will be multiplied by hunger level

var hunger: float = 0.0
var max_hunger: float = 100.0
var hunger_drain_rate: float = 4.5 # % of hunger lost per hour
var hunger_level: int = 1 # Higher levels = faster energy drain

var working: bool = false

## --- TIME ---
var weekday: String = "Monday"

var day: int = 1
var hour: int = 8
var minute: int = 0

var day_start: float = 7.0
var day_end: float = 2.0 # Measured in hours, above 24 is in the AM

var time: float = 8.0 # in hours
var cycle_time: float = 0.33 # between 0.0 and 1.0

var time_speed: float = 12.0
var paused: bool = false
