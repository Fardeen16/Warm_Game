class_name Hands
extends Node3D
## First-person hands (PSX arms rig): the right hand holds the lantern; the left holds a knife
## and only comes up into view while cutting: it draws the knife, then reaches toward the cut and
## saws at it until you let go. The lantern hangs from the right fist but stays upright.

## How far the knife arm reaches toward the cut while cutting (m).
@export var lean: float = 0.2
## Size and speed of the sawing strokes.
@export var saw_distance: float = 0.04
@export var saw_speed: float = 9.0
## Where the lantern hangs below the right fist, in camera space (m).
@export var lantern_offset: Vector3 = Vector3(0.0, -0.27, 0.0)
## The middle of the closed fingers, in the right hand's own space: the handle sits here, not
## at the wrist.
@export var lantern_grip: Vector3 = Vector3(0.0, 0.11, 0.0)

@onready var _right: FPArms = $RightArm
@onready var _left: FPArms = $LeftArm
@onready var _lantern: Node3D = $Lantern

var _left_rest: Vector3
var _cutting := false
var _cut_point := Vector3.ZERO
var _blend := 0.0
var _time := 0.0


func _ready() -> void:
	_left_rest = _left.position
	_left.visible = false
	_left.animation_player.animation_finished.connect(func(_anim: StringName) -> void: _left.play_loop("knife_idle"))


## Called every frame by the player: whether the knife is cutting, and where.
func set_cut(active: bool, point: Vector3) -> void:
	if active and not _cutting:
		_left.visible = true
		_left.play_once("knife_draw")
	_cutting = active
	if active:
		_cut_point = point


func _process(delta: float) -> void:
	# Knife arm rises into view from below while cutting, sinks away after.
	_time += delta
	_blend = move_toward(_blend, 1.0 if _cutting else 0.0, delta * 3.0)
	_left.visible = _blend > 0.0
	var reach := Vector3.ZERO
	if _cutting:
		var toward_cut := (global_transform.affine_inverse() * _cut_point).normalized()
		reach = toward_cut * (lean + sin(_time * saw_speed) * saw_distance)
	_left.position = _left_rest + Vector3(0.0, -0.4, 0.1) * (1.0 - smoothstep(0.0, 1.0, _blend)) + reach * _blend

	# Lantern hangs below the right fist, kept upright.
	var fist := _right.bone_transform("hand.R") * lantern_grip
	_lantern.global_position = fist + global_basis * lantern_offset

