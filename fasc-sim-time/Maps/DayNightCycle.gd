extends Node3D

#var time: float
#@export var day_length: float = 800000.0
@export var start_time: float = 0.25

var time_rate: float = 0.0001

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
	#GameState.cycle_time = start_time
	
	GameState.cycle_time = GameState.time / 24
	
	sun = get_node("Sun")
	moon = get_node("Moon")
	environment = get_node("Sky/WorldEnvironment")
	
	
	handle_time()
	
	sky_material = environment.environment.sky.sky_material

func handle_time():
	GameState.time = 1440 * GameState.cycle_time / 60
	GameState.hour = floor(GameState.time)
	var minute_fraction = GameState.time - GameState.hour
	GameState.minute = 60 * minute_fraction
	
	#print("Hour: %s" % GameState.hour)
	#print("Minute: %s" % GameState.minute)
	#print("It is %s minute" % minute_fraction)
	if GameState.cycle_time >= 1.0:
		#next_day()
		GameState.cycle_time = 0.0
		print("midnight reached")
		EventBus.change_day.emit(GameState.day + 1)

## Controls sun, moon, light, and color of sky
func handle_sky():
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
			#_star_intensity
			#if star_intensity < 1.0:
				#star_intensity += 0.1
				#if star_intensity > 1.0:
					#star_intensity = 1.0
			print("Star intensity: %s" % str(star_intensity))
			#if cloud_shadow_intensity > 0.0:
				#cloud_shadow_intensity -= 0.05
				#if cloud_shadow_intensity < 0.0:
					#cloud_shadow_intensity = 0.0
		#if GameState.time >= 0.3 or GameState.time <= 0.75:
			#if star_intensity > 0.0:
				#star_intensity -= 0.1
				#if star_intensity < 0.0:
					#star_intensity = 0.0
			#if cloud_shadow_intensity < 1.0:
				#cloud_shadow_intensity += 0.05
				#if cloud_shadow_intensity > 1.0:
					#cloud_shadow_intensity = 1.0
		
		environment.environment.sky.sky_material.set_shader_parameter("stars_intensity", star_intensity)
		environment.environment.sky.sky_material.set_shader_parameter("clouds_shadow_intensity", cloud_shadow_intensity)
		#environment.environment.sky.sky_material.set("ground_bottom_color", sky_top_color.sample(GameState.cycle_time))
		#environment.environment.sky.sky_material.set("ground_horizon_color", sky_horizon_color.sample(GameState.cycle_time))

## Rolls over time to a new day
#func next_day():
			##Make it so each day has to be ended, like Stardew. If it reaches a certain time, Player passes out and loses
			##some resource.
			#
			#GameState.cycle_time = 0.0
			#GameState.day += 1
			#GameState.overall_day += 1
			#
			#match GameState.weekday:
				#"Monday":
					#GameState.weekday = "Tuesday"
				#"Tuesday":
					#GameState.weekday = "Wednesday"
				#"Wednesday":
					#GameState.weekday = "Thursday"
				#"Thursday":
					#GameState.weekday = "Friday"
				#"Friday":
					#GameState.weekday = "Saturday"
				#"Saturday":
					#GameState.weekday = "Sunday"
				#"Sunday":
					#GameState.weekday = "Monday"
			#
			#if GameState.day >= 29:
				#GameState.day = 1
				#match GameState.season:
					#"Spring":
						#GameState.season = "Summer"
					#"Summer":
						#GameState.season = "Fall"
					#"Fall":
						#GameState.season = "Winter"
					#"Winter":
						#GameState.season = "Spring"

func handle_lights():
	if GameState.time >= 17.5 or GameState.time < 6.0:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_on()
	else:
		for lamp in get_tree().get_nodes_in_group("lamps"):	
			lamp.light_off()

## Controls time in a more optimized manner than running it in _process()
func _on_timer_timeout() -> void:
	
	#if Objectives.day_1_tour_complete:
	
		GameState.cycle_time += time_rate * GameState.time_speed
		
		#print("Cycle Time: %f" % GameState.cycle_time)
		#print("Time: %f" % GameState.time)
		
		handle_time()
		
		handle_sky()
		
		handle_lights()
		#GameState.time_tracker()
