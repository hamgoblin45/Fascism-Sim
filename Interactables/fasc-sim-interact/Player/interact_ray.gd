extends RayCast3D

var coll


func _unhandled_input(_event: InputEvent) -> void:
	if not coll or not coll is Interactable \
	or GameState.ui_open \
	or GameState.held_item:
		return
	
	if Input.is_action_just_pressed("interact"):
		EventBus.item_interacted.emit(coll.id, "interact", true)
	
	if Input.is_action_just_released("interact"):
		EventBus.item_interacted.emit(coll.id, "interact", false)
	
	if Input.is_action_just_pressed("click"):
		EventBus.item_interacted.emit(coll.id, "click", true)
	
	if Input.is_action_just_released("click"):
		EventBus.item_interacted.emit(coll.id, "click", false)
	
	if Input.is_action_just_pressed("right_click"):
		EventBus.item_interacted.emit(coll.id, "r_click", true)
	
	if Input.is_action_just_released("right_click"):
		EventBus.item_interacted.emit(coll.id, "r_click", false)

func _physics_process(_delta: float) -> void:
	if not get_tree().paused:
	# Clears out any previous interact data
		if self.is_colliding() and not GameState.held_item:
			if coll and coll != self.get_collider():
				EventBus.looking_at_interactable.emit(coll, false)
			coll = self.get_collider()
			if coll is Interactable:
				EventBus.looking_at_interactable.emit(coll, true)
				
		elif coll:
			EventBus.looking_at_interactable.emit(coll, false)
			coll = null
