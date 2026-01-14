extends Node3D



@onready var timer: Timer = $Timer

var sun: DirectionalLight3D
@export var sun_color: Gradient
@export var sun_intensity: Curve

var moon: DirectionalLight3D
@export var moon_color: Gradient
@export var moon_intensity: Curve

# Environment
var environment: WorldEnvironment
var sky_material: Material
@export var sky_top_color: Gradient
@export var sky_horizon_color: Gradient
@export var cloud_light_color: Gradient




func _ready():
	EventBus.main_scene_loaded.connect(_setup)

func _setup():
	sun = get_node("Sun")
	moon = get_node("Moon")
	environment = get_node("Sky/WorldEnvironment")
	
	sky_material = environment.environment.sky.sky_material
	_handle_sky(GameState.hour, GameState.minute)
	EventBus.minute_changed.connect(_handle_sky)



## Controls sun, moon, light, and color of sky
func _handle_sky(_hour: int, _minute: int):
		#SUN
		sun.rotation_degrees.x = GameState.cycle_time * 360 + 90
		sun.light_color = sun_color.sample(GameState.cycle_time)
		sun.light_energy = sun_intensity.sample(GameState.cycle_time)
		
		#MOON
		moon.rotation_degrees.x = GameState.cycle_time * 360 + 270
		moon.light_color = moon_color.sample(GameState.cycle_time)
		moon.light_energy = moon_intensity.sample(GameState.cycle_time)
		
		# VISIBILITY
		sun.visible = sun.light_energy > 0
		moon.visible = moon.light_energy > 0
		
		#SKY COLOR
		environment.environment.sky.sky_material.set_shader_parameter("top_color", sky_top_color.sample(GameState.cycle_time))
		environment.environment.sky.sky_material.set_shader_parameter("bottom_color", sky_horizon_color.sample(GameState.cycle_time))
		environment.environment.sky.sky_material.set_shader_parameter("clouds_light_color", cloud_light_color.sample(GameState.cycle_time))
		
		var star_intensity: float
		var cloud_shadow_intensity: float
		
		if GameState.time < 6.0 or GameState.time > 20.0:
			if star_intensity != 1.0:
				star_intensity = 1.0
			if cloud_shadow_intensity != 0.0:
				cloud_shadow_intensity = 0.0
		elif GameState.time > 8.0 or GameState.time < 18.0:
			if star_intensity != 0.0:
				star_intensity = 0.0
			if cloud_shadow_intensity != 1.0:
				cloud_shadow_intensity = 1.0
			
		if GameState.time > 18.0 and GameState.time <= 20.0:
			star_intensity = (GameState.time - 18.0) / 2
			cloud_shadow_intensity = ((20.0 - GameState.time) / 2)
		
		if GameState.time < 8.0 and GameState.time >= 6.0:
			cloud_shadow_intensity = (GameState.time - 6.0) / 2
			star_intensity = ((8.0 - GameState.time) / 2)
			print("Star intensity: %s" % str(star_intensity))
		
		environment.environment.sky.sky_material.set_shader_parameter("stars_intensity", star_intensity)
		environment.environment.sky.sky_material.set_shader_parameter("clouds_shadow_intensity", cloud_shadow_intensity)
		environment.environment.sky.sky_material.set("ground_bottom_color", sky_top_color.sample(GameState.cycle_time))
		environment.environment.sky.sky_material.set("ground_horizon_color", sky_horizon_color.sample(GameState.cycle_time))
