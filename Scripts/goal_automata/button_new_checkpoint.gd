extends Control

@onready var button := $ButtonNewCheckpoint

var checkpt := load("res://Scenes/DrawingBoard/checkpoint/checkpoint.tscn")
var mg_checkpt := load("res://Scenes/DrawingBoard/checkpoint/mg_checkpoint.tscn")

# instance variables
var in_trans: Arc

# signal
signal add_chkpt_signal(chkpt: Checkpoint, in_trans: Arc)

# Called when the node enters the scene tree for the first time.
func _ready():
	button.pressed.connect(self._button_pressed)

func _button_pressed():
	replace_button_with_checkpoint()
	
func replace_button_with_checkpoint() -> void:
	var new_checkpt
	# load the correct checkpoint based on the options
	if(Options.opts["maintenance_goals"]):
		new_checkpt = mg_checkpt.instantiate()
	else:
		new_checkpt = checkpt.instantiate()
	add_chkpt_signal.emit(new_checkpt, in_trans)
	new_checkpt.set_checkpoint_position(self.position)
	queue_free()

func reposition(diff: int) -> void:
	position.y += diff
	
