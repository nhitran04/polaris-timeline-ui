extends PlanVisElement

class_name PlanVisAction

@onready var action_name := $Panel/ActionDescriptionContainer/ActionName
@onready var action_desc := $Panel/ActionDescriptionContainer/ActionText

func set_action_name(string: String) -> void:
	action_name.text = string

func set_action_desc(string: String) -> void:
	action_desc.text = string

func _on_action_description_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		SignalBus.broadcast_predicates.emit(self.final_st)
