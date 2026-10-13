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

## Extra trees packed along the edge of the square play area (the invisible walls), so the
## map feels closed in by forest. Distances are from the center along x or z.
@export_range(0, 1000) var edge_tree_count: int = 140:
	set(value):
		edge_tree_count = value
		_regenerate()
@export var edge_band: Vector2 = Vector2(14.0, 26.0):
	set(value):
		edge_band = value
		_regenerate()
## Nodes no tree may grow near (the jeep, the bison, the spawn point...).
@export var keep_clear: Array[NodePath] = []:
	set(value):
		keep_clear = value
		_regenerate()
## How far trees stay from each keep_clear node (m).
@export var keep_clear_radius: float = 5.0:
	set(value):
		keep_clear_radius = value
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
	var spots: Array[Vector3] = []
	for i in tree_count:
		var angle := rng.randf() * TAU
		var dist := sqrt(rng.randf_range(inner_radius * inner_radius, outer_radius * outer_radius))
		spots.append(Vector3(cos(angle) * dist, 0.0, sin(angle) * dist))
	for i in edge_tree_count:
		# A random point in the square ring between edge_band.x and edge_band.y.
		var spot := Vector3.ZERO
		while maxf(absf(spot.x), absf(spot.z)) < edge_band.x:
			spot = Vector3(rng.randf_range(-edge_band.y, edge_band.y), 0.0, rng.randf_range(-edge_band.y, edge_band.y))
		spots.append(spot)

	var clear_spots: Array[Vector3] = []
	for path in keep_clear:
		var node := get_node_or_null(path) as Node3D
		if node:
			clear_spots.append(to_local(node.global_position))

	for spot in spots:
		var blocked := false
		for clear in clear_spots:
			if Vector2(spot.x - clear.x, spot.z - clear.z).length() < keep_clear_radius:
				blocked = true
				break
		if blocked:
			continue
		var tree := StaticBody3D.new()
		tree.position = spot
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
