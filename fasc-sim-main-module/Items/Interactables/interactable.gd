extends Area3D
class_name Interactable

const INTERACT_OUTLINE = preload("uid://c3rhvr6bla26v")


@export var id: String = ""

@export var interact_icon: Texture2D
@export var interact_text: String
@export var show_highlight: bool = true

var meshes: Array[MeshInstance3D]

signal interacted(type: String, engaged: bool)

func _ready() -> void:
	EventBus.item_interacted.connect(_interacted)
	EventBus.looking_at_interactable.connect(_look_at_interactable)
	_set_meshes()

func _set_meshes():
	for sibling in get_parent().get_children():
		if sibling is MeshInstance3D:
			meshes.append(sibling)
		else:
			for child in sibling.get_children(true):
				if child is MeshInstance3D:
					meshes.append(child)

func _interacted(object: Interactable, type: String, engaged: bool):
	if object != self:
		return
		
	print("%s detected on %s: %s" % [type, object, engaged])
	
	interacted.emit(type,engaged) # Connect to owner scene in order to handle unique functionaly
	# i.e., turning on a light, playing a sound, etc
	

func _look_at_interactable(interact: Interactable, looking: bool):
	if interact != self or not show_highlight:
		return
	if looking:
		for mesh in meshes:
			mesh.material_overlay = INTERACT_OUTLINE
	else:
		for mesh in meshes:
			mesh.material_overlay = null
