extends RayCast3D

var coll
const OBJECT_OUTLINE_MATERIAL = preload("res://Shaders/object_outline_material.tres")

@onready var interact_check_timer: Timer = $InteractCheckTimer

var interacting: bool

var interact_item: ItemData
var interact_scene

signal display_interact(String, Texture2D)
#signal display_alt_interact(String)
signal hide_interact
#signal hide_alt_interact
signal looking_at_snappable(Area3D)
signal stop_looking_at_snappable



func _unhandled_input(_event: InputEvent) -> void:
	if not Global.ui_open:
		if Input.is_action_just_pressed("interact"):
			if coll and coll is Interactable:
				coll.interact()
		if Input.is_action_just_pressed("click"):
			if coll and coll is Interactable:
				coll.click_interact()
		if Input.is_action_just_pressed("right_click"):
			if coll and coll is Interactable:
				coll.right_click_interact()
				if coll.get_parent() is not GardenPlot:
					if "item_data" in coll.get_parent() and coll.get_parent().item_data and coll.get_parent().item_data.placeable:
						print("Right-click detected on a placeable")
						interact_item = coll.get_parent().item_data
						interact_scene = coll.get_parent()
						Global.ui.start_picking_up_placeable(coll.get_parent().item_data)
						Global.ui.interact_progress_complete.connect(pick_up_placeable)
		if Input.is_action_just_released("right_click"):
			if interact_item:
				interact_item = null

func looking_at_interactable():
	if not Global.ui_open:
		
		## -- Looking at interactables
		#print("LOOKING @ %s" % coll)
		if coll.is_in_group("interactable"):
			if coll.is_in_group("doors") and coll.get_parent().data.locked:
				display_interact.emit("LOCKED", coll.get_parent().locked_icon, coll.click_interact_text, coll.click_interact_icon, coll.r_click_interact_text, coll.r_click_interact_icon)
			else:
				display_interact.emit(coll.interact_text, coll.interact_icon, coll.click_interact_text, coll.click_interact_icon, coll.r_click_interact_text, coll.r_click_interact_icon)
		
		## -- Shop item details
		if coll.is_in_group("purchaseable"):
			coll.get_parent().show_details()
			
		
		## -- Looking at garden
		
		if coll.get_parent().is_in_group("garden"):
			var plot = coll.get_parent()
			if plot.garden_plot_data.plant_data:
				#if not plot.plant_info_panel.visible:
				plot.plant_info_panel.set_info_panel(plot.garden_plot_data)
		
		## - Interactable Highlight Shader
		if coll.get_parent() is MeshInstance3D:
			coll.get_parent().material_override = OBJECT_OUTLINE_MATERIAL
		if coll.get_parent() is StaticBody3D or RigidBody3D or CharacterBody3D:
			for child in coll.get_parent().get_children():
				if child is MeshInstance3D:
					child.material_overlay = OBJECT_OUTLINE_MATERIAL
				elif child.get_children().size() > 0:
					for _child in child.get_children():
						if _child is MeshInstance3D:
							_child.material_overlay = OBJECT_OUTLINE_MATERIAL
	else:
		stop_looking_at_interactable()

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
		#coll.stop_looking_at()
	
		if coll.is_in_group("purchaseable"):
			coll.get_parent().hide_details()
		
		coll = null
	hide_interact.emit()
	stop_looking_at_snappable.emit()
	

func pick_up_placeable():
	Player.get_item(interact_item, 1)
	interact_item = null
	interact_scene.queue_free()
	interact_scene = null

func _on_interact_check_timer_timeout() -> void:
	if self.is_colliding():
		if coll and coll != self.get_collider():
			stop_looking_at_interactable()
		coll = self.get_collider()
		#print("Colliding with " % coll)
		if coll and coll.is_in_group("interactable"):
			#print("Colliding with interactable %s " % coll)
			#coll.looking_at()
			looking_at_interactable()
			
			
		if coll and coll.is_in_group("snappable"):
			looking_at_snappable.emit(coll)
	else:
		
		# Picking up an item crashed here because it queues_free before it stops colliding. 
		# Adding a timer doesn't help; coll doesn't become bull until halfway through the line below
		
			stop_looking_at_interactable()
