extends Node3D


@onready var anim: AnimationPlayer = $door/AnimationPlayer
@onready var interactable: Interactable = $door/Cube/Interactable
@onready var collision_shape: CollisionShape3D = $door/Cube/StaticBody3D/CollisionShape3D


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
				collision_shape.disabled = false
			else:
				anim.play("Open")
				interactable.interact_text = "Close"
				collision_shape.disabled = true
				
				if GameState.raid_in_progress and interactable.id == "front_door":
					EventBus.answering_door.emit()
				
			open = not open
