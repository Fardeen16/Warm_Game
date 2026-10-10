class_name Hands
extends Node3D
## First-person hands: the right hand holds the lantern, the left holds a knife. While cutting,
## the left hand reaches out to the cut and saws along it. Placeholder boxes for now; swap the
## Model nodes for real hands and the Knife for your own model.

## How far the left hand can reach from the camera (m).
@export var reach: float = 0.8
## Distance from the hand to the knife tip, so the tip touches the cut (m).
@export var knife_length: float = 0.2

@onready var _left: Node3D = $LeftHand

var _left_rest: Transform3D
var _cutting := false
var _cut_point := Vector3.ZERO
var _blend := 0.0
var _time := 0.0


func _ready() -> void:
	_left_rest = _left.transform


## Called every frame by the player: whether the knife is cutting, and where.
func set_cut(active: bool, point: Vector3) -> void:
	_cutting = active
	if active:
		_cut_point = point


func _process(delta: float) -> void:
	_time += delta
	_blend = move_toward(_blend, 1.0 if _cutting else 0.0, delta * 3.0)
	if _blend <= 0.0:
		_left.transform = _left_rest
		return

	# Reach from the lower left of the view toward the cut, knife pointing into it.
	var shoulder := global_transform * Vector3(-0.15, -0.2, 0.0)
	var to_cut := _cut_point - shoulder
	var dist := to_cut.length()
	var dir := to_cut / maxf(dist, 0.001)
	var hand_pos := shoulder + dir * clampf(dist - knife_length, 0.1, reach)
	if _cutting:
		# Sawing back and forth.
		hand_pos += dir * sin(_time * 14.0) * 0.02
	var reaching := Transform3D(Basis.looking_at(dir), hand_pos)

	var resting := global_transform * _left_rest
	_left.global_transform = resting.interpolate_with(reaching, smoothstep(0.0, 1.0, _blend))
