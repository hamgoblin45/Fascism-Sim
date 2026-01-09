extends Area3D
class_name Interactable

@export var id: String = ""

@export var interact_icon: Texture2D
@export var interact_text: String



func _ready() -> void:
	EventBus.item_interacted.connect(_interacted)


func _interacted(_id: String, type: String, engaged: bool):
	if _id != id:
		return
		
	print("%s detected on %s: %s" % [type, _id, engaged])
