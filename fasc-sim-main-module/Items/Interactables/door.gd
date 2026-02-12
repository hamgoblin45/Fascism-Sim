extends Node3D


@onready var anim: AnimationPlayer = $door/AnimationPlayer
@onready var interactable: Interactable = $door/Cube/Interactable
@onready var collision_shape: CollisionShape3D = $door/Cube/StaticBody3D/CollisionShape3D

@onready var npc_detect: Area3D = $NPCDetect


var open: bool = false

func _ready() -> void:
	interactable.interacted.connect(_interact)

func _interact(interact_type: String, engaged: bool):
	if not engaged:
		return
	print("click or interact detected on door")
	match interact_type:
		"click","interact":
			
			toggle_door(!open)
				
			if GameState.raid_in_progress:
				if interactable.id == "front_door":
					EventBus.answering_door.emit()
				

func toggle_door(state: bool):
	open = state
	
	if open:
		anim.play("Open")
		interactable.interact_text = "Close"
		#collision_shape.disabled = true
		collision_shape.set_deferred("disabled", true)
		
	else:
		anim.play("Close")
		interactable.interact_text = "Open"
		await anim.animation_finished
		collision_shape.disabled = false

func _on_npc_detect_body_entered(body: Node3D) -> void:
	if body is NPC:
		if not open and interactable.id != "front_door":
			toggle_door(true) # force open for npc
			# Animate the npc opening a door
