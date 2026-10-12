class_name FPArms
extends Node3D
## First-person arms from the PSX arms rig (assets/models/characters/player/arms). Put this under
## a Camera3D with the rig as its child, turned to face the camera and dropped so the rig's own
## camera point sits at the camera (rotation 180 on Y, position 0, -1.743, 0).

## Animation to hold while idle (looped).
@export var idle_animation: String = "knife_idle"
@export_enum("Both", "Right only", "Left only") var show_arms: int = 0
## Winter gloves instead of bare hands.
@export var gloves: bool = true

const GLOVES_TEXTURE := preload("res://assets/models/characters/player/arms/arms_gloves_01.png")

var animation_player: AnimationPlayer
var skeleton: Skeleton3D


func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false)
	skeleton = find_child("Skeleton3D", true, false)

	# Your own arms shouldn't throw shadows from the lantern or the moon.
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	if gloves:
		for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
			if mesh.get_parent() != skeleton:
				continue
			var mat := mesh.get_active_material(0)
			if mat is StandardMaterial3D:
				mat = mat.duplicate()
				mat.albedo_texture = GLOVES_TEXTURE
				mesh.material_override = mat

	if show_arms != 0:
		var hider := HideBones.new()
		hider.bones = PackedStringArray(["shoulder.L"] if show_arms == 1 else ["shoulder.R"])
		skeleton.add_child(hider)

	play_loop(idle_animation)


## Plays an animation over and over.
func play_loop(anim: String) -> void:
	var animation := animation_player.get_animation(anim)
	if animation:
		animation.loop_mode = Animation.LOOP_LINEAR
		animation_player.play(anim, 0.2)


## Plays an animation once, blending in.
func play_once(anim: String, blend: float = 0.15) -> void:
	animation_player.play(anim, blend)


## World transform of a bone, e.g. "hand.R".
func bone_transform(bone_name: String) -> Transform3D:
	var bone := skeleton.find_bone(bone_name)
	return skeleton.global_transform * skeleton.get_bone_global_pose(bone)
