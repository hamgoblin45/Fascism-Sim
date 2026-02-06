extends Node3D

@export var item_data: InventoryItemData
@onready var shapecast: ShapeCast3D = $ShapeCast3D

@export_group("Swing Settings")
var swing_power: float = 0.0
var power_max: float = 1.0
var power_build_speed: float = 1.5
@export var stamina_cost_per_sec: float = 20.0
@export var shake_intensity: float = 0.05

@export_group("Visual Offsets")
var default_pos: Vector3 = Vector3.ZERO
var windup_offset: Vector3 = Vector3(0.1, -0.1, 0.2) # Pull back and to the side
var swing_forward_dist: float = -1.0 # How far it swings

enum State {IDLE, CHARGING, SWINGING, RECOVERING}
var current_state = State.IDLE

func _physics_process(delta: float) -> void:
	if GameState.equipped_item != item_data:
		return
	
	match current_state:
		State.IDLE:
			if Input.is_action_just_pressed("click"):
				current_state = State.CHARGING
		State.CHARGING:
			if Input.is_action_pressed("click"):
				# Drain stamina
				GameState.stamina -= stamina_cost_per_sec
				
				# Build up swing power
				swing_power = move_toward(swing_power, power_max, power_build_speed * delta)
				
				# Procedural shaking
				var current_shake = (swing_power / power_max) * shake_intensity
				var shake_offset = Vector3(
					randf_range(-current_shake, current_shake),
					randf_range(-current_shake, current_shake),
					randf_range(-current_shake, current_shake)
				)
				
				# Windup position + shake
				position = lerp(position, default_pos + windup_offset + shake_offset, 0.1)
				rotation_degrees.x = lerp(rotation_degrees.x, 15.0, 0.1)
	
			else:
				_on_release()

#func _unhandled_input(_event: InputEvent) -> void:
	#if Input.is_action_just_released("click") and swing_power > 0:
		#_on_release()
#
#func _handle_hold_click(delta: float):
	#if swing_power < power_max:
		#swing_power += power_build_speed * delta

func _on_release():
	print("SWINGING with a swing power of ", swing_power)
	if current_state != State.CHARGING: return
	current_state = State.SWINGING
	
	# Create swing movement
	var tween = create_tween().set_parallel(true)
	var swing_time = 0.15 # Fast forward movement
	
	# Lunge forward
	tween.tween_property(self, "position", Vector3(0, 0, swing_forward_dist), swing_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees:x", -45.0, swing_time)
	
	# Hit detection only during movement
	_check_hit()
	
	# Reset to idle after a recovery interval
	tween.chain().tween_interval(0.2)
	tween.chain().tween_callback(_reset_to_idle)

func _check_hit():
	shapecast.enabled = true
	# Manually force shapecast to update while swinging
	shapecast.force_shapecast_update()
	
	if shapecast.is_colliding():
		for i in range(shapecast.get_collision_count()):
			var target = shapecast.get_collider(i)
			if target.has_method("take_damage"): # Maybe change this to a class name or something
				# Apply damage based on swing power
				var damage = 10.0 * (1.0 + swing_power)
				target.take_damage(damage)
				print("Hit ", target, " for ", damage)
	
	shapecast.enabled = false

func _reset_to_idle():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", default_pos, 0.3)
	tween.tween_property(self, "rotation_degrees", Vector3.ZERO, 0.3)
	swing_power = 0.0
	current_state = State.IDLE
