class_name Arm
extends MeshInstance3D
## Stretches this 1 m long arm mesh from a shoulder point to a hand, every frame.

## The hand this arm ends at.
@export var hand: Node3D
## Where the arm starts, in the parent's space (e.g. below and behind the camera).
@export var shoulder: Vector3 = Vector3(0.0, -0.45, 0.15)


func _process(_delta: float) -> void:
	if hand == null:
		return
	var parent := get_parent_node_3d()
	var from := parent.global_transform * shoulder
	var to := hand.global_transform * Vector3(0.0, 0.0, 0.05)
	var along := to - from
	var length := along.length()
	if length < 0.001:
		return
	var basis := Basis.looking_at(along / length, parent.global_basis.y) * Basis.from_scale(Vector3(1.0, 1.0, length))
	global_transform = Transform3D(basis, (from + to) * 0.5)
