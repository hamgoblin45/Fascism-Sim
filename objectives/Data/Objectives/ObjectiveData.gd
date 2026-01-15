extends Resource
class_name ObjectiveData

@export var name: String = ""
@export var id: String = ""
@export var description: String = ""

@export var step_datas: Array[ObjectiveStepData]

var complete: bool = false
var failed: bool = false
