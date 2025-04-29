extends RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	add_theme_color_override("default_color", Color.TRANSPARENT)

func _show() -> void:
	add_theme_color_override("default_color", Color(0.435, 0.435, 0.435, 1.0))

func _hide() -> void:
	add_theme_color_override("default_color", Color.TRANSPARENT)
