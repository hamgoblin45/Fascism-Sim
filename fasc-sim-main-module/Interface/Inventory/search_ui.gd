extends Control

@onready var raid_in_progress_label: Label = %RaidInProgressLabel
@onready var answer_door_timer_label: Label = %AnswerDoorTimerLabel




func _ready() -> void:
	EventBus.raid_starting.connect(_on_raid_starting)
	SearchManager.raid_finished.connect(_on_raid_finished)
	
	EventBus.raid_timer_updated.connect(_on_raid_timer_updated)
	EventBus.answering_door.connect(_on_door_answered)


func _on_raid_starting():
	show()
	#raid_in_progress_label.show()

func _on_raid_finished():
	hide()

func _on_raid_timer_updated(value: float):
	if value <= 1.0: hide()
	answer_door_timer_label.text = "ANSWER DOOR: %s SECONDS" % str(value)

func _on_door_answered():
	answer_door_timer_label.text = ""
