extends RigidBody3D
class_name Grabbable

#@export var id: String = ""

#@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@export var interact_area: Interactable

var original_parent
var current_parent
var held: bool



func _ready():
	_set_pickup()

func _set_pickup():
	#Attach unique meshes and make coll shapes local & adjust for individual items
	# Also set id and interact text/images in the interactable node
	original_parent = get_parent()
	interact_area.interacted.connect(_interact)

func _interact(type: String, engaged: bool):
	match type:
		"click":
			if engaged:
				EventBus.item_grabbed.emit(self)
				held = true
				print("Item grabbed")
			else:
				EventBus.item_dropped.emit()
				held = false
		
		"r_click":
			print("R Click detected on a grabbable")
		
		"interact":
			print("Will interact in full game")
