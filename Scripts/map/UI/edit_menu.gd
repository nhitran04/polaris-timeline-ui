extends Control

@onready var custom_button := $Custom as Button
	
func _show_menu(pos: Vector2, obj: Node3D) -> void:
	if obj is Region:
		custom_button.show()
		custom_button.text = "Delete Region"
		custom_button.add_theme_color_override("font_color", Color(1.0, 0, 0))
		custom_button.pressed.connect(_delete.bind(obj))
	elif obj is Surface:
		custom_button.show()
		custom_button.text = "Delete Surface"
		custom_button.add_theme_color_override("font_color", Color(1.0, 0, 0))
		custom_button.pressed.connect(_delete.bind(obj))
	elif obj is Item:
		custom_button.show()
		custom_button.text = "Delete Entity"
		custom_button.add_theme_color_override("font_color", Color(1.0, 0, 0))
		custom_button.pressed.connect(_delete.bind(obj))
	elif obj is Person:
		custom_button.show()
		custom_button.text = "Delete Person"
		custom_button.add_theme_color_override("font_color", Color(1.0, 0, 0))
		custom_button.pressed.connect(_delete.bind(obj))
	elif obj is AreaNode:
		custom_button.show()
		custom_button.text = "Delete Node"
		custom_button.add_theme_color_override("font_color", Color(1.0, 0, 0))
		custom_button.pressed.connect(_delete.bind(obj))
	visible = true
	position = pos

func _hide_menu() -> void:
	visible = false
	if len(custom_button.text) > 0:
		custom_button.pressed.disconnect(_delete)
	custom_button.text = ""
	custom_button.add_theme_color_override("font_color", Color(0, 0, 0))
	custom_button.hide()

func _delete(obj: Node3D) -> void:
	obj.delete()
	_hide_menu()
