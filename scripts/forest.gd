@tool
extends Node3D
## Scatters trees around the origin so there is something to see in the storm. Uses the tree
## models in tree_models (picked at random); with none set it falls back to simple cone pines.

@export_range(0, 1000) var tree_count: int = 90:
	set(value):
		tree_count = value
		_regenerate()
## Keeps the spawn area clear.
@export var inner_radius: float = 6.0:
	set(value):
		inner_radius = value
		_regenerate()
@export var outer_radius: float = 45.0:
	set(value):
		outer_radius = value
		_regenerate()
@export var random_seed: int = 1:
	set(value):
		random_seed = value
		_regenerate()

## Tree models to scatter. Leave empty for simple placeholder pines.
@export var tree_models: Array[PackedScene] = []:
	set(value):
		tree_models = value
		_regenerate()
## Random size multiplier for each tree model.
@export var model_scale: Vector2 = Vector2(1.3, 2.2):
	set(value):
		model_scale = value
		_regenerate()
## Turn applied to every model, e.g. (90, 0, 0) for models exported lying down (Z-up).
@export var model_rotation: Vector3 = Vector3.ZERO:
	set(value):
		model_rotation = value
		_regenerate()

var _container: Node3D


func _ready() -> void:
	_regenerate()


func _regenerate() -> void:
	if not is_node_ready():
		return
	if _container:
		_container.queue_free()
	_container = Node3D.new()
	add_child(_container, false, Node.INTERNAL_MODE_FRONT)

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.18, 0.12, 0.08)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.1, 0.2, 0.15)
	var snow_mat := StandardMaterial3D.new()
	snow_mat.albedo_color = Color(0.85, 0.88, 0.95)

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.2
	trunk_mesh.bottom_radius = 0.25
	trunk_mesh.height = 1.5
	trunk_mesh.material = trunk_mat
	var leaf_mesh := CylinderMesh.new()
	leaf_mesh.top_radius = 0.0
	leaf_mesh.bottom_radius = 1.6
	leaf_mesh.height = 4.0
	leaf_mesh.material = leaf_mat
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.0
	cap_mesh.bottom_radius = 0.75
	cap_mesh.height = 1.9
	cap_mesh.material = snow_mat
	var trunk_shape := CylinderShape3D.new()
	trunk_shape.radius = 0.35 if tree_models.is_empty() else 0.2
	trunk_shape.height = 3.0

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	# Stand the trees on the snow if there is uneven terrain.
	var terrain := get_tree().get_first_node_in_group("snow_terrain") if is_inside_tree() else null
	for i in tree_count:
		var angle := rng.randf() * TAU
		var dist := sqrt(rng.randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
		var tree := StaticBody3D.new()
		tree.position = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		if terrain:
			# Sink a little so the trunk doesn't hover on a slope.
			var world := to_global(tree.position)
			tree.position.y = to_local(Vector3(world.x, terrain.get_height(world.x, world.z), world.z)).y - 0.15
		tree.rotation.y = rng.randf() * TAU
		_container.add_child(tree)

		if tree_models.is_empty():
			tree.scale = Vector3.ONE * rng.randf_range(0.7, 1.6)
			_add_mesh(tree, trunk_mesh, 0.75)
			_add_mesh(tree, leaf_mesh, 3.5)
			_add_mesh(tree, cap_mesh, 4.6)
		else:
			tree.scale = Vector3.ONE * rng.randf_range(model_scale.x, model_scale.y)
			var model := tree_models[rng.randi() % tree_models.size()].instantiate() as Node3D
			model.rotation_degrees = model_rotation
			tree.add_child(model)
		var collider := CollisionShape3D.new()
		collider.shape = trunk_shape
		collider.position.y = 1.5
		tree.add_child(collider)


func _add_mesh(parent: Node3D, mesh: Mesh, height: float) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position.y = height
	parent.add_child(instance)
