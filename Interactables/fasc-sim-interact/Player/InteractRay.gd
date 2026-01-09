extends RayCast3D

var coll
const OBJECT_OUTLINE_MATERIAL = preload("res://Shaders/object_outline_material.tres")

signal display_interact(String)
signal display_alt_interact(String)
signal hide_interact
signal hide_alt_interact

func _process(_delta):
	#var coll_parent = self.get_collider()
	
	
	if self.is_colliding():
		coll = self.get_collider()
		#print(coll)
		if coll and coll.is_in_group("interactable"):
			#coll.looking_at()
			if coll.pre_interact_text:
				display_interact.emit(coll.pre_interact_text)
			if coll.alt_interact_text:
				display_alt_interact.emit(coll.alt_interact_text)
			
			for child in coll.get_parent().get_children():
				if child is MeshInstance3D:
					child.material_override = OBJECT_OUTLINE_MATERIAL
			
			if Input.is_action_just_pressed("interact"):
				coll.interact()
			if Input.is_action_just_released("interact"):
				coll.disengage()
			if Input.is_action_just_pressed("click"):
				coll.click_interact()
			if Input.is_action_just_pressed("right_click"):
				coll.right_click_interact()
				
	else:
		if coll and coll.is_in_group("interactable"):
			if coll.pre_interact_text:
				hide_interact.emit()
			if coll.alt_interact_text:
				hide_alt_interact.emit()
			for child in coll.get_parent().get_children():
				if child is MeshInstance3D:
					child.material_override = null
			#coll.stop_looking_at()
		coll = null
		
