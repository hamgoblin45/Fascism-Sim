extends RayCast3D

var coll
#const OBJECT_OUTLINE_MATERIAL = preload("res://Shaders/object_outline_material.tres")

@onready var interact_check_timer: Timer = $InteractCheckTimer

var interacting: bool


signal display_interact(String, Texture2D)
#signal display_alt_interact(String)
signal hide_interact
#signal hide_alt_interact
signal looking_at_snappable(Area3D)
signal stop_looking_at_snappable


#func _ready() -> void:
	#EventBus.look_at_item.connect()

func _unhandled_input(_event: InputEvent) -> void:
	if not coll or not GameState.ui_open:
		return
	if Input.is_action_just_pressed("interact"):
		if coll and coll is Interactable:
			coll.interact()
	if Input.is_action_just_pressed("click"):
		if coll and coll is Interactable:
			#coll.click_interact()
			EventBus.item_interacted.emit(coll.id, "click", true)
	if Input.is_action_just_released("click"):
		if coll and coll is Interactable:
			#coll.click_interact()
			EventBus.item_interacted.emit(coll.id, "click", true)
	if Input.is_action_just_pressed("right_click"):
		if coll and coll is Interactable:
			EventBus.item_interacted.emit(coll.id, "r_click", true)
			#coll.right_click_interact()
	if Input.is_action_just_released("right_click"):
		EventBus.item_interacted.emit(coll.id, "r_click", false)

#func looking_at_interactable():
	#if not GameState.ui_open:
		#
		### -- Looking at interactables
		##print("LOOKING @ %s" % coll)
		#if coll is Interactable:
		#
		### - Interactable Highlight Shader
		##if coll.get_parent() is MeshInstance3D:
			##coll.get_parent().material_override = OBJECT_OUTLINE_MATERIAL
		##if coll.get_parent() is StaticBody3D or RigidBody3D or CharacterBody3D:
			##for child in coll.get_parent().get_children():
				##if child is MeshInstance3D:
					##child.material_overlay = OBJECT_OUTLINE_MATERIAL
				##elif child.get_children().size() > 0:
					##for _child in child.get_children():
						##if _child is MeshInstance3D:
							##_child.material_overlay = OBJECT_OUTLINE_MATERIAL
	#else:
		#stop_looking_at_interactable()

func stop_looking_at_interactable():
	if is_instance_valid(coll):
		if coll.is_in_group("interactable"):
			if coll.get_parent() is MeshInstance3D:
				coll.get_parent().material_overlay = null
			if coll.get_parent().get_children().size() > 0:
				for child in coll.get_parent().get_children():
					if child is MeshInstance3D:
						child.material_overlay = null
					elif child.get_children().size() > 0:
						for _child in child.get_children():
							if _child is MeshInstance3D:
								_child.material_overlay = null
		
		coll = null
	hide_interact.emit()

func _on_interact_check_timer_timeout() -> void:
	if self.is_colliding():
		if coll and coll != self.get_collider():
			stop_looking_at_interactable()
		coll = self.get_collider()
		#print("Colliding with " % coll)
		#if coll and coll is Interactable:
			#print("Colliding with interactable %s " % coll)
			#coll.looking_at()
			#looking_at_interactable()
			
	else:
		
		# Picking up an item crashed here because it queues_free before it stops colliding. 
		# Adding a timer doesn't help; coll doesn't become bull until halfway through the line below
		
			stop_looking_at_interactable()
