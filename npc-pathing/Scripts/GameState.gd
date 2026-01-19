extends Node

var player: CharacterBody3D


var weekday: String = "Monday"

var day: int = 1
var hour: int = 8
var minute: int = 0

var day_start: float = 18.0
var day_end: float = 2.0 # Measured in hours, above 24 is in the AM

var time: float = 8.0 # in hours
var cycle_time: float = 0.33 # between 0.0 and 1.0

var time_speed: float = 4.0
var paused: bool = false
