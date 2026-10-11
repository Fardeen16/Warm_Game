@tool
class_name SnowTerrain
extends StaticBody3D
## Uneven snowy ground: gentle drifts and hollows from noise, flattened around chosen nodes
## (the bison, the spawn point) so they sit on level snow. Builds its mesh and matching
## collision at load, in the editor too. Other scripts can ask get_height(x, z).

@export_range(10.0, 400.0, 1.0) var size: float = 120.0:
	set(value):
		size = value
		_rebuild()
## Height of the drifts (m).
@export_range(0.0, 3.0, 0.05) var bumpiness: float = 0.8:
	set(value):
		bumpiness = value
		_rebuild()
## Higher = smaller, more frequent drifts.
@export_range(0.005, 0.3, 0.005) var drift_frequency: float = 0.05:
	set(value):
		drift_frequency = value
		_rebuild()
@export var random_seed: int = 7:
	set(value):
		random_seed = value
		_rebuild()
## Nodes that get level ground around them.
@export var flatten_around: Array[NodePath] = []:
	set(value):
		flatten_around = value
		_rebuild()
@export_range(0.5, 20.0, 0.5) var flat_radius: float = 4.0:
	set(value):
		flat_radius = value
		_rebuild()
@export var material: Material:
	set(value):
		material = value
		if _mesh_instance:
			_mesh_instance.material_override = material

var _noise: FastNoiseLite
var _flat_spots: Array[Vector2] = []
var _mesh_instance: MeshInstance3D
var _collider: CollisionShape3D


func _enter_tree() -> void:
	add_to_group("snow_terrain")


func _ready() -> void:
	_rebuild()


## Ground height at a world x/z position.
func get_height(x: float, z: float) -> float:
	if _noise == null:
		_setup_noise()
	var local := to_local(Vector3(x, 0.0, z)) if is_inside_tree() else Vector3(x, 0.0, z)
	var h := _noise.get_noise_2d(local.x, local.z) * bumpiness
	for spot in _flat_spots:
		var d := spot.distance_to(Vector2(local.x, local.z))
		h *= smoothstep(flat_radius * 0.6, flat_radius, d)
	return h + (global_position.y if is_inside_tree() else 0.0)


func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = drift_frequency
	_noise.fractal_octaves = 3
	_noise.seed = random_seed


func _rebuild() -> void:
	if not is_node_ready():
		return
	_setup_noise()
	_flat_spots.clear()
	for path in flatten_around:
		var node := get_node_or_null(path) as Node3D
		if node:
			var local := to_local(node.global_position)
			_flat_spots.append(Vector2(local.x, local.z))

	# One vertex per meter, shared by the mesh and the collision so feet match the snow.
	var count := int(size) + 1
	var half := (count - 1) * 0.5
	var heights := PackedFloat32Array()
	heights.resize(count * count)
	for z in count:
		for x in count:
			heights[z * count + x] = get_height(x - half, z - half) - global_position.y

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in count:
		for x in count:
			st.set_uv(Vector2(x, z))
			st.add_vertex(Vector3(x - half, heights[z * count + x], z - half))
	for z in count - 1:
		for x in count - 1:
			var i := z * count + x
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(i + count)
			st.add_index(i + 1)
			st.add_index(i + count + 1)
			st.add_index(i + count)
	st.generate_normals()
	st.generate_tangents()

	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance, false, Node.INTERNAL_MODE_FRONT)
		_collider = CollisionShape3D.new()
		add_child(_collider, false, Node.INTERNAL_MODE_FRONT)
	_mesh_instance.mesh = st.commit()
	_mesh_instance.material_override = material

	var shape := HeightMapShape3D.new()
	shape.map_width = count
	shape.map_depth = count
	shape.map_data = heights
	_collider.shape = shape
