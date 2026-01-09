extends Node3D

@onready var look_at_node: Node3D = $"../LookAtNode"
@onready var camera: Camera3D = $Camera

var original_trans: Transform3D

var zoomed: bool
var zoom

func _ready() -> void:
	original_trans = camera.global_transform
	
	

func _process(delta: float) -> void:
	#if test_on:
		#look_at_node.look_at(teddy_pos)
	if Global.looking_at:
		
		#camera.global_transform = camera.global_transform.interpolate_with(Global.looking_at.dialog_cam_point.global_transform, 0.7 * delta)
		
		if Global.looking_at.head:
			look_at_target(Global.looking_at.head)
		else:
			look_at_target(Global.looking_at)
		#
		#rotation.y = lerp(rotation.y, look_at_node.rotation.y, 0.75 * delta)
		#rotation.x = lerp(rotation.x, look_at_node.rotation.x, 0.75 * delta)
		#rotation.z = lerp(rotation.z, look_at_node.rotation.z, 0.75 * delta)
		#camera.position.z = lerp(camera.position.z, -1.0, 0.75 * delta)
		#if not zoomed:
			#camera.position.z -= 0.55
			#if camera.position.z <= -2:
				#zoomed = true
		##else:
			##camera.position.x = lerp(camera.position.x, zoom, 0.75 * delta)
	#else:
		#camera.global_transform = Transform3D.ZERO
	#elif camera.global_transform != original_trans:
		#camera.global_transform = camera.global_transform.interpolate_with(original_trans, 0.9 * delta)
		#zoomed = false

func look_at_target(target):
	look_at_node.look_at(target.global_position)
