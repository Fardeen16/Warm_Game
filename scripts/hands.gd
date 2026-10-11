class_name Hands
extends Node3D
## First-person hands: the right hand holds the lantern; the left holds a knife and only comes
## up into view while cutting, reaching out to the cut and sawing along it. Each hand has a
## forearm running back to a shoulder point below and behind the camera, so the hands read as
## part of the body. Placeholder boxes for now; swap the Model, Arm and Knife meshes for real ones.

## How far the left hand can reach from the camera (m).
@export var reach: float = 0.8
## Distance from the hand to the knife tip, so the tip touches the cut (m).
@export var knife_length: float = 0.2
## Where each arm starts, relative to the camera: below and just behind the view.
@export var right_shoulder: Vector3 = Vector3(0.28, -0.45, 0.15)
@export var left_shoulder: Vector3 = Vector3(-0.28, -0.45, 0.15)

@onready var _right: Node3D = $RightHand
@onready var _left: Node3D = $LeftHand
@onready var _right_arm: Node3D = $RightArm
@onready var _left_arm: Node3D = $LeftArm

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
	_update_left_hand(delta)
	_fit_arm(_right_arm, right_shoulder, _right)
	_fit_arm(_left_arm, left_shoulder, _left)


func _update_left_hand(delta: float) -> void:
	_blend = move_toward(_blend, 1.0 if _cutting else 0.0, delta * 3.0)
	# Out of sight below the view unless cutting.
	_left.visible = _blend > 0.0
	_left_arm.visible = _left.visible
	if _blend <= 0.0:
		_left.transform = _left_rest
		return

	# Reach toward the cut, knife pointing into it.
	var shoulder := global_transform * left_shoulder
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


## Stretches a 1 m long arm mesh from the shoulder to the back of the hand.
func _fit_arm(arm: Node3D, shoulder_local: Vector3, hand: Node3D) -> void:
	var shoulder := global_transform * shoulder_local
	var wrist := hand.global_transform * Vector3(0.0, 0.0, 0.05)
	var along := wrist - shoulder
	var length := along.length()
	if length < 0.001:
		return
	var basis := Basis.looking_at(along / length, global_basis.y) * Basis.from_scale(Vector3(1.0, 1.0, length))
	arm.global_transform = Transform3D(basis, (shoulder + wrist) * 0.5)
