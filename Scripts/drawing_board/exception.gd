extends HBoxContainer

var icon_scene := load("res://Scenes/DrawingBoard/exceptions/icon.tscn")

func set_as_nothing() -> void:
	pass

func set_as_error() -> void:
	var icon = icon_scene.instantiate()
	add_child(icon)
	get_node("message").set("theme_override_colors/font_color", Color.BLACK)
