extends Control

@onready var panel_container := $PanelContainer
@onready var not_finished_notification := $PanelContainer/VBoxContainer/NotFinished as RichTextLabel
@onready var ok_button := $PanelContainer/VBoxContainer/OK/OK as Button
@onready var are_you_finished_notification := $PanelContainer/VBoxContainer/AreYouFinished as RichTextLabel
@onready var yesno_option := $PanelContainer/VBoxContainer/YesNo as HBoxContainer
@onready var yes_button := $PanelContainer/VBoxContainer/YesNo/Yes as Button
@onready var no_button := $PanelContainer/VBoxContainer/YesNo/No as Button

# end screen
var end_screen_scene := load("res://Scenes/experimentation/end.tscn")

# instance variables
var computation_countdown: bool
var countdown: int

# Called when the node enters the scene tree for the first time.
func _ready():
	
	yes_button.pressed.connect(_participant_is_done)
	no_button.pressed.connect(_hide_notification)
	ok_button.pressed.connect(_hide_notification)
	
	computation_countdown = false
	countdown = 1
	
	SignalBus.be_done.connect(_participant_is_done)
	SignalBus.remove_end_screen.connect(_hide_notification)
	
	# resize control
	get_viewport().connect("size_changed", _on_viewport_resize)
	_on_viewport_resize()
	
func _process(delta: float) -> void:
	if computation_countdown:
		if countdown == 0:
			SignalBus.participant_is_done.emit()
			computation_countdown = false
		else:
			countdown -= 1
	
func set_is_participant_finished(unfinished: Array[String]) -> void:
	if len(unfinished) > 0:
		are_you_finished_notification.hide()
		yesno_option.hide()
		not_finished_notification.text += " "
		for i in range(len(unfinished)):
			var item = unfinished[i]
			not_finished_notification.text += " " + _color_item_text(item)
			if i < len(unfinished) - 1:
				not_finished_notification.text += " and"
		# not_finished_notification.text += ".\n\nUse the dropdown menu on the top-left portion of the interface to select items to convey the possible location(s) of."
	else:
		not_finished_notification.hide()
		ok_button.hide()
		are_you_finished_notification.text = "Are you finished telling the robot about [b]ALL locations[/b] that it can find the " + _color_item_text(Options.opts["curr_item"]) + "?"
		are_you_finished_notification.text += "\n\nRemember, you can use the slider bar above the interface to refresh your memory for where the items might be."
	panel_container.size.y = 0
		
func _color_item_text(str: String) -> String:
	if str == "umbrella":
		return "[color=cyan]" + str + "[/color]"
	elif str == "bag":
		return "[color=gold]" + str + "[/color]"
	else:
		return str
		
func _participant_is_done() -> void:
	if int(Options.opts["items_specified"]) < 2:
		Options.add_option("items_specified", "2")
		if Options.opts["curr_item"] == "umbrella":
			Options.add_option("curr_item", "bag")
			SignalBus.set_curr_item.emit("bag")
		else:
			Options.add_option("curr_item", "umbrella")
			SignalBus.set_curr_item.emit("umbrella")
		_hide_notification()
		SignalBus.load_begin_screen.emit()
	else:
		# send signal to compute probabilities and finish
		var end_screen = end_screen_scene.instantiate()
		add_child(end_screen)
		Logger.log_event("button_participant_is_finished", {})
		
		# defer computation
		computation_countdown = true
	
func _hide_notification() -> void:
	Logger.log_event("button_hide_done_notification", {})
	get_parent().remove_child(self)
	queue_free()

func _on_viewport_resize() -> void:
	pass
	'''
	var vp = get_viewport()
	if vp != null:
		var vp_size = Vector2(vp.size)
		panel_container.position.x = vp_size.x/2.0 - panel_container.size.x/2.0
		panel_container.position.y = vp_size.y/2.0 - panel_container.size.y/2.0
	'''
