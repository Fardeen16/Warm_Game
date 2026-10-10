@tool
extends Node3D
## Restrained flailing, grasping and elastic yanks using the existing CC0 arm rig.

var right_grasp := false
var left_grasp := false
var thrash := Vector2.ZERO
var pull_strength := 0.0
var _time := 0.0
var _configured := false
var _skeleton: Skeleton3D
var _poses: Array[Transform3D] = []
var _open: Array[Transform3D] = []
var _right_hand := -1
var _left_hand := -1
var _right_basis := Basis.IDENTITY
var _left_basis := Basis.IDENTITY
var _right_close := 0.0
var _left_close := 0.0


func _ready() -> void:
	call_deferred("_configure")


func _sample(player: AnimationPlayer, wanted: String) -> void:
	for candidate in player.get_animation_list():
		if String(candidate).replace("_", ".") == wanted:
			player.play(candidate)
			player.advance(player.get_animation(candidate).length * 0.85)
			player.pause()
			_skeleton.force_update_all_bone_transforms()
			return


func _configure() -> void:
	_skeleton = $Arms/ArmsRig/Skeleton3D
	var animation: AnimationPlayer = $Arms/AnimationPlayer
	_sample(animation, "relax")
	for bone in range(_skeleton.get_bone_count()):
		_open.append(_skeleton.get_bone_pose(bone))
	_sample(animation, "grab.R")
	for bone in range(_skeleton.get_bone_count()):
		_poses.append(_skeleton.get_bone_pose(bone))
	_right_hand = _skeleton.find_bone("hand.R")
	_left_hand = _skeleton.find_bone("hand.L")
	_right_basis = global_basis.inverse() * _skeleton.global_basis * _skeleton.get_bone_global_pose(_right_hand).basis
	_sample(animation, "grab.L")
	for bone in range(_skeleton.get_bone_count()):
		if _skeleton.get_bone_name(bone).ends_with(".L"):
			_poses[bone] = _skeleton.get_bone_pose(bone)
	_left_basis = global_basis.inverse() * _skeleton.global_basis * _skeleton.get_bone_global_pose(_left_hand).basis
	animation.stop(true)
	var skin := ShaderMaterial.new()
	skin.shader = preload("res://shaders/bloody_arms.gdshader")
	skin.set_shader_parameter("skin_texture", preload("res://assets/models/psx_arms/arms_01.png"))
	var mesh: MeshInstance3D = $Arms/ArmsRig/Skeleton3D/ArmsMesh
	mesh.material_override = skin
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_configured = true
	_update_pose()


func yank() -> void:
	if right_grasp or left_grasp:
		pull_strength = 1.0


func wrist_world(right: bool) -> Vector3:
	if not _configured:
		return to_global(Vector3(0.16 if right else -0.16, 0.01, -0.30))
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(_right_hand if right else _left_hand).origin


func grip_world(right: bool) -> Vector3:
	if not _configured:
		return wrist_world(right)
	var side := "R" if right else "L"
	var center := Vector3.ZERO
	for joint in ["01", "02"]:
		var bone := _skeleton.find_bone("f_middle.%s.%s" % [joint, side])
		center += _skeleton.get_bone_global_pose(bone).origin
	var palm := _skeleton.global_transform * (center * 0.5)
	return wrist_world(right).lerp(palm, _right_close if right else _left_close)


func _process(delta: float) -> void:
	if not _configured:
		return
	if not Engine.is_editor_hint():
		_time += delta
		pull_strength = move_toward(pull_strength, 0.0, delta * 2.4)
	_right_close = move_toward(_right_close, 1.0 if right_grasp else 0.0, delta * 7.0)
	_left_close = move_toward(_left_close, 1.0 if left_grasp else 0.0, delta * 7.0)
	_update_pose()


func _update_pose() -> void:
	for bone in range(_poses.size()):
		var pose := _poses[bone]
		var label := _skeleton.get_bone_name(bone)
		if label.begins_with("f_"):
			pose = _open[bone].interpolate_with(pose, _right_close if label.ends_with(".R") else _left_close)
		_skeleton.set_bone_pose(bone, pose)
	_skeleton.force_update_all_bone_transforms()
	for side in ["R", "L"]:
		var right: bool = side == "R"
		var sign_value := 1.0 if right else -1.0
		var grasp := _right_close if right else _left_close
		var phase := _time * 4.5 + (0.0 if right else 2.1)
		var flail := (1.0 - grasp) * (0.35 + thrash.length() * 0.65)
		var target := Vector3(sign_value * 0.16, 0.01, -0.30)
		target += Vector3(sin(phase) * 0.038, cos(phase * 1.3) * 0.042, sin(phase * 0.8) * 0.024) * flail
		target += Vector3(thrash.x * 0.018, -absf(thrash.y) * 0.008, 0.0)
		target += Vector3(-sign_value * 0.025, -0.065, 0.09) * pull_strength * grasp
		_solve_arm(side, _right_hand if right else _left_hand, target, _right_basis if right else _left_basis)


func _solve_arm(side: String, hand: int, target: Vector3, hand_basis: Basis) -> void:
	var destination := _skeleton.to_local(to_global(target))
	var forearm := _skeleton.find_bone("forearm." + side)
	var upper := _skeleton.find_bone("upper_arm." + side)
	if hand < 0 or forearm < 0 or upper < 0:
		return
	for iteration in range(8):
		for joint in [forearm, upper]:
			var pose := _skeleton.get_bone_global_pose(joint)
			var from := _skeleton.get_bone_global_pose(hand).origin - pose.origin
			var toward := destination - pose.origin
			if from.length_squared() < 0.00001 or toward.length_squared() < 0.00001:
				continue
			pose.basis = Basis(Quaternion(from.normalized(), toward.normalized())) * pose.basis
			_skeleton.set_bone_global_pose(joint, pose)
			_skeleton.force_update_all_bone_transforms()
	var palm := _skeleton.get_bone_global_pose(hand)
	palm.basis = (_skeleton.global_basis.inverse() * global_basis * hand_basis).orthonormalized()
	_skeleton.set_bone_global_pose(hand, palm)
	_skeleton.force_update_all_bone_transforms()
