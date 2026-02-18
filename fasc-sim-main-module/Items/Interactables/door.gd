extends Node3D


@onready var anim: AnimationPlayer = $door/AnimationPlayer
@onready var interactable: Interactable = $door/Cube/Interactable
@onready var collision_shape: CollisionShape3D = $door/Cube/StaticBody3D/CollisionShape3D

@onready var npc_detect: Area3D = $NPCDetect


var open: bool = false

func _ready() -> void:
	interactable.interacted.connect(_interact)

func _interact(interact_type: String, engaged: bool):
	if not engaged: return
	
	match interact_type:
		"interact":
			toggle_door(!open)
			
			# NEW: If the door is being opened and it's the front door
			if open and interactable.id == "front_door":
				if GameState.raid_in_progress:
					EventBus.answering_door.emit()
				else:
					# Tell the VisitorManager to start dialogue with whoever is waiting
					EventBus.door_opened_for_visitor.emit()
				

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
