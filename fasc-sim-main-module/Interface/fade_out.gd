extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

@onready var consequence_label: Label = %ConsequenceLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton

func _ready():
	hide()
	color_rect.modulate.a = 0
	
	EventBus.player_arrested.connect(_on_arrested)
	EventBus.game_over.connect(_on_game_over)

func _on_arrested():
	_trigger_consequence("YOU HAVE BEEN ARRESTED")

func _on_game_over():
	_trigger_consequence("GAME OVER")

func _trigger_consequence(text: String):
	await get_tree().create_timer(0.05).timeout
	show()
	consequence_label.text = text
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 2.0)
	
	# Unlock mouse and pause background action
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
