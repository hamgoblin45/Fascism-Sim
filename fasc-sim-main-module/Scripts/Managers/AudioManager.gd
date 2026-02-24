extends Node

# A library of all our sound files. 
# Key: String name (e.g., "knock"), Value: AudioStream (the actual audio file)
@export var sounds: Dictionary = {}

func _ready() -> void:
	# Optional: Set process mode to ALWAYS if you want UI sounds to play while paused
	process_mode = Node.PROCESS_MODE_ALWAYS

# ---------------------------------------------------------
# 1. 2D AUDIO (For UI, Music, Voiceovers, or non-directional sounds)
# ---------------------------------------------------------
func play_2d(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer:
	if not sounds.has(sound_name):
		push_warning("AudioManager: Sound '%s' not found in library." % sound_name)
		return null
		
	var player = AudioStreamPlayer.new()
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	
	# Add it to the Autoload so it survives scene changes
	add_child(player)
	player.play()
	
	# Clean up the node when the sound finishes
	player.finished.connect(player.queue_free)
	
	return player

# ---------------------------------------------------------
# 2. 3D AUDIO (For footsteps, knocking, spatial interactions)
# ---------------------------------------------------------
func play_3d(sound_name: String, position: Vector3, volume_db: float = 0.0, pitch: float = 1.0) -> AudioStreamPlayer3D:
	if not sounds.has(sound_name):
		push_warning("AudioManager: Sound '%s' not found in library." % sound_name)
		return null
		
	var player = AudioStreamPlayer3D.new()
	player.stream = sounds[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = pitch
	
	# 3D specifics to make it fade out naturally over distance
	player.max_distance = 25.0 
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	
	# We must add 3D sounds to the active level scene, NOT the Autoload root, 
	# so it correctly interacts with the 3D physics space.
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(player)
		player.global_position = position
		player.play()
		
		# Clean up
		player.finished.connect(player.queue_free)
	else:
		player.queue_free()
		return null
		
	return player
