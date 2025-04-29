extends HBoxContainer

class_name CheckboxItem

@onready var check := $Checkbox/Check as TextureRect
@onready var label := $Label as Label

func set_text(msg: String) -> void:
	label.text = msg

func complete() -> void:
	#var check_img = Image.load_from_file("res://Assets/img/checkmark.png")
	#check_img.resize(40, 40)
	#var tex: ImageTexture = ImageTexture.create_from_image(check_img)
	var img_texture_path := "res://Assets/img/checkmark.png"
	var img_texture: CompressedTexture2D = load(img_texture_path)
	var check_img: Image = img_texture.get_image()
	check_img.resize(40, 40)
	var tex: ImageTexture = ImageTexture.create_from_image(check_img)
	check.texture = tex
