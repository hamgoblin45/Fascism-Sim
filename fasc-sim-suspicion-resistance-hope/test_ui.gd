extends Control


@export var test_npc_hope: float = 0.0 # Will be stored in NPCData

@onready var suspicion_progress_bar: ProgressBar = %SuspicionProgressBar
@onready var suspicion_state: RichTextLabel = %SuspicionState
@onready var resist_progress_bar: ProgressBar = %ResistProgressBar
@onready var resist_value: Label = %ResistValue
@onready var hope_value: Label = %HopeValue



func _ready() -> void:
	EventBus.suspicion_changed.connect(_on_suspicion_changed)
	EventBus.resistance_changed.connect(_on_resist_changed)
	EventBus.npc_hope_changed.connect(_on_hope_changed)
	_set_regime_response()


func _on_suspicion_changed(new_value: float):
	suspicion_progress_bar.value = new_value
	_set_regime_response()
	#suspicion_value.text = str(new_value)

func _set_regime_response():
	if GameState.suspicion < 10:
		suspicion_state.text = "[center][color=green]Privileges Granted"
	elif GameState.suspicion >= 10 and GameState.suspicion < 20:
		suspicion_state.text = "[center][color=blue]Searches unlikely but possible"
	elif GameState.suspicion >= 20 and GameState.suspicion < 30:
		suspicion_state.text = "[center][color=yellowgreen]Random searches"
	elif GameState.suspicion >= 30 and GameState.suspicion < 40:
		suspicion_state.text = "[center][color=yellow]Expect searches and carry papers"
	elif GameState.suspicion >= 40 and GameState.suspicion < 50:
		suspicion_state.text = "[center][color=yelloworange]Regular searches"
	elif GameState.suspicion >= 50 and GameState.suspicion < 60:
		suspicion_state.text = "[center][color=orange]Full police state"
	elif GameState.suspicion >= 60 and GameState.suspicion < 70:
		suspicion_state.text = "[center][color=orangered]They think you may be a traitor"
	elif GameState.suspicion >= 70 and GameState.suspicion < 80:
		suspicion_state.text = "[center][color=red]They are sure you are a traitor"
	elif GameState.suspicion >= 80 and GameState.suspicion < 90:
		suspicion_state.text = "[center][color=darkred]You are wanted for questioning"
	elif GameState.suspicion >= 90:
		suspicion_state.text = "[center][color=black]You are to be tried and executed"

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
	EventBus.change_resistance.emit(0.5)
	EventBus.change_suspicion.emit(3.5)


func _on_provide_real_intel_pressed() -> void:
	EventBus.output.emit("You gave the Regime a real tip against the Rebels")
	EventBus.change_resistance.emit(-6.0)
	EventBus.change_suspicion.emit(-6.0)


func _on_provide_fake_intel_pressed() -> void:
	EventBus.output.emit("You gave the Regime a fake tip against the Rebels")
	EventBus.change_resistance.emit(1.0)
	EventBus.change_suspicion.emit(0.5)


func _on_give_evidence_pressed() -> void:
	EventBus.output.emit("You gave the Regime damning evidence against the Rebels")
	EventBus.change_resistance.emit(-15)
	EventBus.change_suspicion.emit(-12)

func _on_inspire_pressed() -> void:
	EventBus.output.emit("You inspired a neighbor")
	EventBus.change_npc_hope.emit("test_npc", 1.8)

func _on_doom_pressed() -> void:
	EventBus.output.emit("You brought a neighbor down with bad news")
	EventBus.change_npc_hope.emit("test_npc", -0.75)

func _on_threaten_pressed() -> void:
	EventBus.output.emit("You threatened a neighbor")
	EventBus.change_npc_hope.emit("test_npc", -2.5)

func _on_denial_pressed() -> void:
	EventBus.output.emit("You downplayed the danger to a neighbor")
	EventBus.change_npc_hope.emit("test_npc", -0.3)


func _on_comfort_pressed() -> void:
	EventBus.output.emit("You comforted a neighbor")
	EventBus.change_npc_hope.emit("test_npc", 0.8)


func _on_demean_pressed() -> void:
	EventBus.output.emit("You demeaned a neighbor")
	EventBus.change_npc_hope.emit("test_npc", -1.5)
