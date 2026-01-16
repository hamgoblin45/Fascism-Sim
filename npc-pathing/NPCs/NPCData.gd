extends Resource
class_name NPCData

@export var name: String
#@export var madtalk_sheet_id: String = ""
var current_dialogue_data: DialogueData
@export var dialogues: Array[DialogueData]
@export var intro_dialogue: DialogueData
#@export var current_dialogue_title_dict: Dictionary
#@export var current_dialogue_title_string: String
#var path: Curve3D
var current_path: PathData
@export var schedule: ScheduleData
var start_path_time: float

@export var waiting_for_player: bool

@export var opinion: float
var met: bool

#@export var current_text_thread: TextThreadData
@export var all_texts: Array[TextMessageData]
#@export var text_data_history: Array[TextMessageData]
var text_history: Array[Dictionary]
var unread_messages: bool

@export var node: PackedScene = preload("res://Characters/npc.tscn")
@export var mesh: PackedScene
var instance
@export var current_map: String



signal update_path(Curve3D, bool)
signal update_dialogue(String)



func select_dialogue():
	
	if not met and intro_dialogue:
		set_dialogue(intro_dialogue)
		return
	
	var selected_dialogue
	for dialogue in dialogues:
		#if not current_dialogue_data:
			#selected_dialogue = dialogues[0]
			#break
		if dialogue == selected_dialogue and dialogue.one_shot and dialogues.size() > dialogues.find(dialogue):
			selected_dialogue = dialogues[dialogues.find(dialogue) + 1]
			break
		#if dialogue == current_dialogue_data:
			#break
		if dialogue.day and dialogue.day != GameTime.day:
			continue
		if dialogue.time and dialogue.time <= GameTime.time:
			continue
		if dialogue.req_current_objective and not Objectives.current_objectives.has(dialogue.req_current_objective):
			continue
		if dialogue.req_completed_objective and not Objectives.current_objectives.has(dialogue.req_completed_objective):
			continue
		if dialogue.weather and dialogue.weather != GameTime.weather:
			continue
		selected_dialogue = dialogue
		break
	
	if selected_dialogue:
		set_dialogue(selected_dialogue)
		return
		

func set_dialogue(dialogue_data: DialogueData):
	current_dialogue_data = dialogue_data
	if current_dialogue_data is not GenericDialogueData:
		current_dialogue_data.set_dialogue()
	dialogues.erase(dialogue_data)


func set_route():
	if schedule:
		print("Setting routine via NPCData's set_route() func")
		schedule.set_routine()

func set_text_message():
	pass
