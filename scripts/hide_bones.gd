class_name HideBones
extends SkeletonModifier3D
## Shrinks the listed bones (and everything attached to them) to nothing after animation, e.g.
## to show only one arm of a two-armed rig.

@export var bones: PackedStringArray = []


func _process_modification_with_delta(_delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	for bone_name in bones:
		var bone := skeleton.find_bone(bone_name)
		if bone >= 0:
			skeleton.set_bone_pose_scale(bone, Vector3.ONE * 0.0001)
