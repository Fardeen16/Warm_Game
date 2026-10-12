class_name HandGrip
extends SkeletonModifier3D
## Poses a grip on top of whatever the arms are animating: curls the fingers and thumb of one
## hand and can turn the wrist, e.g. to wrap a hand around something it holds.

## Which hand: "R" or "L".
@export var side: String = "R"
## Bend at each finger joint (degrees). Around 30 is a loose hold, 60+ a tight fist.
@export_range(-30.0, 120.0, 1.0) var finger_curl: float = 40.0
## Bend at each thumb joint (degrees).
@export_range(-60.0, 90.0, 1.0) var thumb_curl: float = 15.0
## Extra turn of the wrist (degrees, in the hand's own axes).
@export var wrist_turn: Vector3 = Vector3.ZERO

const FINGERS := ["f_index", "f_middle", "f_ring", "f_pinky"]


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	var wrist := skeleton.find_bone("hand." + side)
	if wrist >= 0 and wrist_turn != Vector3.ZERO:
		var turn := Quaternion.from_euler(wrist_turn * PI / 180.0)
		skeleton.set_bone_pose_rotation(wrist, skeleton.get_bone_pose_rotation(wrist) * turn)
	for finger in FINGERS:
		_curl(skeleton, finger, finger_curl)
	_curl(skeleton, "thumb", thumb_curl)


func _curl(skeleton: Skeleton3D, finger: String, degrees: float) -> void:
	var bend := Quaternion(Vector3.RIGHT, deg_to_rad(degrees))
	for joint in ["01", "02", "03"]:
		var bone := skeleton.find_bone("%s.%s.%s" % [finger, joint, side])
		if bone >= 0:
			skeleton.set_bone_pose_rotation(bone, skeleton.get_bone_pose_rotation(bone) * bend)
