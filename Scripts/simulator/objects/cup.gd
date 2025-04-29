extends StaticBody2D

@onready var _cup_sprite = $cup_sprite

var reset_pos_coords: Vector2
var reset_parent_name: String = "simulator"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos_coords = position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset() -> void:
	_cup_sprite.texture = load("res://Assets/img/simulator/objects/empty-cup.png")
	position = reset_pos_coords

func set_full(is_full: bool) -> void:
	await get_tree().create_timer(1.3).timeout
	if is_full:
		_cup_sprite.texture = load("res://Assets/img/simulator/objects/full-cup.png")
	else:
		_cup_sprite.texture = load("res://Assets/img/simulator/objects/empty-cup.png")

	SignalBus.current_action_finished.emit()

func set_empty() -> void:
	_cup_sprite.texture = load("res://Assets/img/simulator/objects/empty-cup.png")
