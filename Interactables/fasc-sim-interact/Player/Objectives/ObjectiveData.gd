extends Resource
class_name ObjectiveData

@export var title: String
@export var description: String

@export var turn_in_npc: NPCData

@export var due_date: int
@export var due_season: String
@export var due_time: float

@export var required_items: Array[SlotData]
#@export var steps: Dictionary = {}
#@export var steps: Array[String]
#@export var current_step: String
@export var steps: Array[ObjectiveStepData]
@export var current_step: ObjectiveStepData

#@export var current_step_desc: String
#@export var next_step_desc: String

#@export var final_step: String
var ready_to_turn_in: bool
@export var complete: bool

@export var reward_items: Array[SlotData]
@export var reward_skill: String
@export var reward_xp: float
@export var reward_opinion: float

#signal update_step(ObjectiveData, String)
signal update_step(ObjectiveData, ObjectiveStepData)
signal objective_complete(ObjectiveData)

func set_objective():
	if steps.size() > 0:
		current_step = steps[0]
		Player.update_objective(self, current_step)
		#update_step.emit(self, current_step)
	
		print("Assigned objective: %s" % title)
		print("Current step: %s" % current_step.step_text)
	
	if current_step.req_items.size() > 0:
		check_for_required_items()

func advance_step():
	#var index: int = 0
	var step = steps.find(current_step)
	step += 1
	if step >= steps.size():
		if turn_in_npc:
			ready_to_turn_in = true
		else:
			complete_objective()
	else:
		current_step = steps[step]
		#update_step.emit(self, current_step)
		Player.update_objective(self, current_step)
	print("ADVANCING OBJECTIVE STEP to %s" % current_step.step_text)

func check_for_required_items() -> bool:
	if required_items.size() > 0:
		for slot in current_step.req_items:
			var has_item: bool = false
			for _slot in Player.HOTBAR_DATA.slot_datas:
				if _slot.item_data == slot.item_data:
					if _slot.quantity >= slot.quantity:
						has_item = true
			for _slot in Player.BACKPACK_DATA.slot_datas:
				if _slot and _slot.item_data == slot.item_data:
					if _slot.quantity >= slot.quantity:
						has_item = true
			if not has_item:
				return false
	return true

func complete_objective():
	complete = true
	
	if reward_skill:
		Player.award_xp(reward_skill,reward_xp)
	if turn_in_npc and reward_opinion > 0:
		turn_in_npc.opinion += reward_opinion
	if reward_items.size() > 0:
		for item in reward_items:
			Player.get_item(item.item_data, item.quantity)
	
	if Objectives.current_objectives.has(self):
		Objectives.current_objectives.erase(self)
		if not Objectives.completed_objectives.has(self):
			Objectives.completed_objectives.append(self)
			
	#objective_complete.emit(self)
	Player.complete_objective(self)
	#Global.ui.complete_tracked_objective(self)
	
		
		#Insert some cool objective complete anim / fanfare here or connected to objective_complete signal
	print("%s complete" % title)
