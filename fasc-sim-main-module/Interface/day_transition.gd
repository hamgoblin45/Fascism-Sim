extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

@onready var consequence_label: Label = %ConsequenceLabel

@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready():
	await get_tree().process_frame
	hide()
	color_rect.modulate.a = 0
	
	EventBus.player_arrested.connect(_on_arrested)
	EventBus.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)

func _on_arrested():
	_trigger_consequence("YOU HAVE BEEN ARRESTED")
	restart_button.text = "Serve Time (Next Day)"

func _on_game_over():
	_trigger_consequence("GAME OVER")
	restart_button.text = "Restart Game"

func _trigger_consequence(text: String):
	show()
	consequence_label.show()
	restart_button.show()
	
	consequence_label.text = text
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)
	
	get_tree().paused = true
	
	call_deferred("_force_mouse_visible")

func _force_mouse_visible():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed():
	get_tree().paused = false
	
	if consequence_label.text == "GAME OVER":
		get_tree().reload_current_scene()
	else:
		# Hide text/buttons, keep screen black
		consequence_label.hide()
		restart_button.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
		# Hand off to the DayManager
		DayManager.process_transition(true)

# --- NEW: FADE LOGIC FOR SLEEPING / WAKING ---

func fade_out_for_sleep(duration: float = 1.5) -> Signal:
	show()
	consequence_label.hide()
	restart_button.hide()
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	
	# This returns the actual Signal object that DayManager is awaiting
	return tween.finished

func fade_in(duration: float = 2.0):
	# Ensure text is hidden just in case
	consequence_label.hide()
	restart_button.hide()
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	tween.tween_callback(hide) # Deactivate layer when done
