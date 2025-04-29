extends TextEdit


# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.remove_labels_focus.connect(_dehighlight)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _adjust_size() -> void:
	var v: Vector2
	v = get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT,
											  -1,
											  get_theme_font_size("font_size"))

func _dehighlight() -> void:
	release_focus()
