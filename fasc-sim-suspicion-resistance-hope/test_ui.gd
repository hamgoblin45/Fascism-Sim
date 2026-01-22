extends Control


@export var test_npc_hope: float = 0.0 # Will be stored in NPCData

@onready var suspicion_progress_bar: ProgressBar = %SuspicionProgressBar
@onready var suspicion_value: Label = %SuspicionValue
@onready var resist_progress_bar: ProgressBar = %ResistProgressBar
@onready var resist_value: Label = %ResistValue
@onready var hope_value: Label = %HopeValue



func _ready() -> void:
	EventBus.suspicion_changed.connect(_on_suspicion_changed)
	EventBus.resistance_changed.connect(_on_resist_changed)
	EventBus.npc_hope_changed.connect(_on_hope_changed)


func _on_suspicion_changed(new_value: float):
	suspicion_progress_bar.value = new_value
	suspicion_value.text = str(new_value)

func _on_resist_changed(new_value: float):
	resist_progress_bar.value = new_value
	resist_value.text = str(new_value)

func _on_hope_changed(_npc_id: String, new_value: float):
	hope_value.text = str(new_value)


func _on_interrogate_neutral_pressed() -> void:
	EventBus.output.emit("You gave the Regime a neutral response")
	EventBus.change_resistance.emit(-0.25)


func _on_interrogate_snarky_pressed() -> void:
	EventBus.output.emit("You gave the Regime a snarky response")
	EventBus.change_resistance.emit(0.25)
	EventBus.change_suspicion.emit(2.0)


func _on_interrogate_hostile_pressed() -> void:
	EventBus.output.emit("You gave the Regime a hostile response")


func _on_provide_real_intel_pressed() -> void:
	EventBus.output.emit("You gave the Regime real evidence against the Rebels")


func _on_provide_fake_intel_pressed() -> void:
	EventBus.output.emit("You gave the Regime fake evidence against the Rebels")


func _on_give_evidence_pressed() -> void:
	pass # Replace with function body.
