extends CanvasLayer

@onready var build_menu := $BuildMenu as Control
@onready var param_menu := $ParamMenu as ColorPicker
@onready var uncert_item_menu := $UncertControls as VBoxContainer
@onready var uncert_key := $Key as Panel
@onready var tutorial_menu := $CameraTutorial as PanelContainer

# scenes to be instantiated
var done_button_scene := load("res://Scenes/experimentation/finish.tscn")
var done_notification := load("res://Scenes/experimentation/notification.tscn")

enum UI_MODE {BUILD,
			  PARAMETERIZE,
			  SET_UNCERTAINTY}
var mode := UI_MODE.BUILD

# instance variables
var menu_visible: bool

# Called when the node enters the scene tree for the first time.
func _ready():
	menu_visible = false
	SignalBus.activate_build_mode.connect(_activate_build_mode)
	SignalBus.activate_param_mode.connect(_activate_param_mode)
	SignalBus.activate_uncert_mode.connect(_activate_uncert_mode)
	SignalBus.edit_menu_toggle.connect(_toggle_menu)
	SignalBus.edit_menu_show.connect(_show_menu)
	SignalBus.edit_menu_hide.connect(_hide_menu)
	
	# tutorial
	SignalBus.show_uncert_key.connect(_show_key)
	SignalBus.show_uncert_controls.connect(_show_uncert_controls)
	SignalBus.show_tutorial_menu.connect(_show_tutorial_menu)
	
	# experimentation
	SignalBus.add_done_button.connect(_add_done_button)
	SignalBus.participant_finished.connect(_on_participant_finished)
	
func _activate_build_mode() -> void:
	mode = UI_MODE.BUILD
	uncert_item_menu.hide()
	uncert_key.hide()
	
func _activate_param_mode() -> void:
	mode = UI_MODE.PARAMETERIZE
	uncert_item_menu.hide()
	uncert_key.hide()
	
func _activate_uncert_mode() -> void:
	mode = UI_MODE.SET_UNCERTAINTY
	uncert_item_menu.select_and_show()
	uncert_key.show()

func _toggle_menu(pos: Vector2, obj: Node3D) -> void:
	if menu_visible:
		_hide_menu()
	else:
		_show_menu(pos, obj)
	
func _show_menu(pos: Vector2, obj: Node3D) -> void:
	SignalBus.remove_labels_focus.emit()
	if mode == UI_MODE.BUILD:
		build_menu._show_menu(pos, obj)
		menu_visible = true
	elif mode == UI_MODE.PARAMETERIZE:
		param_menu._show_menu(pos, obj)
		menu_visible = true

func _hide_menu() -> void:
	build_menu._hide_menu()
	param_menu._hide_menu()
	menu_visible = false
	
func _show_key(show: bool) -> void:
	if show:
		uncert_key.visible = true
	else:
		uncert_key.visible = false

func _show_uncert_controls(show: bool) -> void:
	if show:
		uncert_item_menu.visible = true
	else:
		uncert_item_menu.visible = false

func _show_tutorial_menu(show: bool) -> void:
	if show:
		tutorial_menu.visible = true
	else:
		tutorial_menu.visible = false
		
func _add_done_button() -> void:
	var done_button = done_button_scene.instantiate()
	add_child(done_button)

func _on_participant_finished() -> void:
	var notif = done_notification.instantiate()
	add_child(notif)
	var unspecified_items: Array[String] = []
	if Options.opts.uncert_paint:
		var paint_status = uncert_item_menu.get_paint_status()
		for item in paint_status:
			if not paint_status[item]:
				unspecified_items.append(item)
	else:
		var item_lists = uncert_item_menu.get_item_lists()
		for item in item_lists:
			if len(item_lists[item]) == 0:
				unspecified_items.append(item)
	notif.set_is_participant_finished(unspecified_items)
