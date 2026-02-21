extends Control

@onready var raid_in_progress_label: Label = %RaidInProgressLabel
@onready var answer_door_timer_label: Label = %AnswerDoorTimerLabel
@onready var frisk_warning: Label = %FriskWarning

@onready var busted_label: Label = %BustedLabel
@onready var clear_label: Label = %ClearLabel

var pulse_tween: Tween

func _ready() -> void:
	EventBus.raid_starting.connect(_on_raid_starting)
	SearchManager.raid_finished.connect(_on_raid_finished)
	EventBus.raid_timer_updated.connect(_on_raid_timer_updated)
	EventBus.answering_door.connect(_on_door_answered)
	
	SearchManager.search_step_started.connect(_on_search_started)
	SearchManager.search_finished.connect(_on_search_finished)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended) # Clear on dialogue close
	
	hide()
	frisk_warning.hide()
	if busted_label: busted_label.hide()
	if clear_label: clear_label.hide()

func _on_raid_starting():
	show()
	# Only show raid timer/labels, make sure frisk is hidden
	frisk_warning.hide()

func _on_search_started(inv: InventoryData, index: int, duration: float):
	# ONLY show Frisk Warning if our pockets are being searched
	if inv == GameState.pockets_inventory:
		show()
		frisk_warning.show()
		if not pulse_tween or not pulse_tween.is_valid():
			_start_pulsing()

func _start_pulsing():
	pulse_tween = create_tween().set_loops() # Loop infinitely
	pulse_tween.tween_property(frisk_warning, "modulate:a", 0.2, 0.5)
	pulse_tween.tween_property(frisk_warning, "modulate:a", 1.0, 0.5)

# Added the index parameter to match the updated signal
func _on_search_finished(caught: bool, item: ItemData, qty: int, index: int = -1):
	_hide_warnings()
	
	if caught:
		# Show Busted! (It will be cleared automatically when interrogation ends)
		if busted_label: 
			busted_label.show()
	else:
		# Show Clear temporarily if the player themselves was searched
		# (We check frisk_warning's previous state indirectly or just flash it anyway)
		if clear_label:
			clear_label.show()
			await get_tree().create_timer(1.5).timeout
			if clear_label: clear_label.hide()
			
	if not GameState.raid_in_progress:
		pass # Any extra cleanup if it was a standalone search

func _on_dialogue_ended():
	# Dialogic is done, remove the Busted warning
	if busted_label: 
		busted_label.hide()
	frisk_warning.hide()
	_hide_warnings()

func _on_raid_finished():
	hide()
	_hide_warnings()

func _on_raid_timer_updated(value: float):
	if value <= 1.0: hide()
	answer_door_timer_label.text = "ANSWER DOOR: %s SECONDS" % str(value)

func _on_door_answered():
	answer_door_timer_label.text = ""

func _hide_warnings():
	hide()
	if pulse_tween:
		pulse_tween.kill()
