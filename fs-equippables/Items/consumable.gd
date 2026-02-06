extends Node3D

@export var item_data: ConsumableData
@export var consume_speed: float = 0.25 # percent (0.0-1.0) consumed per second

var default_pos: Vector3 = Vector3.ZERO
var eating_pos: Vector3 = Vector3(0, -0.15, -0.25) # Closer to face

func _physics_process(delta: float) -> void:
	if GameState.equipped_item != item_data:
		return
	
	if Input.is_action_pressed("click") and item_data.remaining > 0:
		_process_consume(delta)
	else:
		_animate(false)

func _process_consume(delta: float):
	var amount_to_consume = consume_speed * delta
	
	amount_to_consume = min(amount_to_consume, item_data.remaining)
	
	item_data.remaining -= amount_to_consume
	
	for stat_name in item_data.effects:
		var total_benefit = item_data.effects[stat_name]
		var frame_benefit = total_benefit * amount_to_consume
		
		EventBus.change_stat.emit(stat_name, frame_benefit)
	
	if item_data.remaining <= 0:
		_on_finished()

func _animate(active: bool):
	var target_pos = eating_pos if active else default_pos
	var jitter = Vector3.ZERO
	if active:
		jitter = Vector3(randf_range(-0.002, 0.002), randf_range(-0.002, 0.002), 0)
	position = lerp(position, target_pos + jitter, 0.1)
	rotation_degrees.x = lerp(rotation_degrees.x, (15.0 if active else 0.0), 0.1)

func _on_finished():
	print("Item consumed!")
	EventBus.removing_item.emit(item_data, 1, null)
	GameState.equipped_item
