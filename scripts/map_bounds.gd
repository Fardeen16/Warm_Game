@tool
class_name MapBounds
extends Node3D
## Invisible walls around a square play area centered on this node.
## The walls are only drawn in the editor.

@export_range(5.0, 200.0, 1.0) var map_size: float = 40.0:
	set(value):
		map_size = value
		_rebuild()
@export_range(1.0, 50.0, 0.5) var wall_height: float = 10.0:
	set(value):
		wall_height = value
		_rebuild()

const WALL_THICKNESS := 1.0

var _container: Node3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	if _container:
		_container.queue_free()
	_container = Node3D.new()
	add_child(_container, false, Node.INTERNAL_MODE_FRONT)

	var editor_mat := StandardMaterial3D.new()
	editor_mat.albedo_color = Color(1.0, 0.3, 0.2, 0.15)
	editor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	editor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	editor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var half := (map_size + WALL_THICKNESS) * 0.5
	var long := map_size + WALL_THICKNESS * 2.0
	var walls := [
		[Vector3(0, 0, -half), Vector3(long, wall_height, WALL_THICKNESS)],
		[Vector3(0, 0, half), Vector3(long, wall_height, WALL_THICKNESS)],
		[Vector3(-half, 0, 0), Vector3(WALL_THICKNESS, wall_height, long)],
		[Vector3(half, 0, 0), Vector3(WALL_THICKNESS, wall_height, long)],
	]
	for wall in walls:
		var body := StaticBody3D.new()
		body.position = wall[0] + Vector3.UP * wall_height * 0.5
		_container.add_child(body)

		var shape := BoxShape3D.new()
		shape.size = wall[1]
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)

		if Engine.is_editor_hint():
			var mesh := BoxMesh.new()
			mesh.size = wall[1]
			mesh.material = editor_mat
			var preview := MeshInstance3D.new()
			preview.mesh = mesh
			body.add_child(preview)
