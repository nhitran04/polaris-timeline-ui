extends Sprite2D

var seconds_passed: float
var degrees := [0, 45, 90, 135, 180, 225, 270, 315]
var idx: int

func _ready():
	seconds_passed = 0
	idx = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	seconds_passed += delta
	if seconds_passed > 0.2:
		seconds_passed -= 0.2
		idx += 1
		idx %= len(degrees)
		rotation = deg_to_rad(degrees[idx])
