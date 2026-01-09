extends FloatableBody3D
class_name Pickup3D


@export var slot_data: SlotData

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var interact_area: Interactable = $InteractArea

var held: bool



func _ready():
	set_pickup()

func set_pickup():
	if slot_data.item_data:
		if slot_data.item_data.mesh:
			mesh_instance.queue_free()
			var new_instance = slot_data.item_data.mesh.instantiate()
			add_child(new_instance)
	
	if Global.current_map_name != "store":
		interact_area.interacted.connect(get_item)
	
	interact_area.click.connect(click)

#func _process(delta: float) -> void:
	#if held:
		#global_position = global_position.lerp(Global.player.hold_item_point.global_position, delta * 0.5)

func get_item():
	Player.get_item(slot_data.item_data, slot_data.quantity)
	
	# -- Handle Artifact discovery
	if slot_data.item_data and slot_data.item_data is ArtifactData:
		print("Pickup is an artifact")
		for discovery in Save.discovered_artifacts:
			if discovery.item_data == slot_data.item_data:
				print("Already discovered %s"% slot_data.item_data.name)
				return
				
		var new_discovery = DiscoveryData.new()
		new_discovery.item_data = slot_data.item_data
		new_discovery.set_discovery("artifact")
		
		Save.discovered_artifacts.append(new_discovery)
		Global.ui.phone_ui.discoveries_screen.set_discoveries()
	
	
	get_parent().remove_child(self)
	queue_free()

func click():
	print("Click detected on an item that can be picked up")
	if not Global.player.held_object:
		print("Player has no held object, trying")
		Global.player.set_held_object(self)
	
