extends Node3D


@onready var anim: AnimationPlayer = $door/AnimationPlayer
@onready var interactable: Interactable = $door/Cube/Interactable



var open: bool = false

func _ready() -> void:
	interactable.interacted.connect(_interact)

func _interact(interact_type: String, engaged: bool):
	if not engaged:
		return
	print("click or interact detected on door")
	match interact_type:
		"click","interact":
			
			if open:
				anim.play("Close")
				interactable.interact_text = "Open"
			else:
				anim.play("Open")
				interactable.interact_text = "Close"
			open = not open
