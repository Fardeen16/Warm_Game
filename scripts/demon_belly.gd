@tool
extends Node3D
## A compressed living chamber holding the survivor in elastic flesh restraints.

@export var cavity_dimensions := Vector3(0.72, 0.62, 1.9)
@export_range(0.0, 1.0, 0.05) var flesh_wetness := 0.7
@export_range(0.0, 1.0, 0.05) var demon_life := 0.6
@export_range(0.0, 1.0, 0.01) var blood_screen_intensity := 0.08
@export_range(-40.0, 0.0, 1.0) var heartbeat_volume_db := -25.0
@export var seal_entrance := true
@export var mouse_sensitivity := 0.0017

const FLOOR_Y := -0.32
var _time := 0.0
var _yaw := 0.0
var _pitch := -0.10
var _thrash := Vector2.ZERO
var _restraints: Array[MeshInstance3D] = []
var _material: ShaderMaterial
var _floor_material: ShaderMaterial
var _overlay: ShaderMaterial
var _seal: MeshInstance3D
var _heartbeat: AudioStreamPlayer
var _body: CharacterBody3D
var _camera: Camera3D
var _hands: Node3D


func _ready() -> void:
	_body = $View
	_camera = $View/Camera3D
	_hands = $View/Hands
	_build_chamber()
	_overlay = ShaderMaterial.new()
	_overlay.shader = preload("res://shaders/carcass_vignette.gdshader")
	$UI/AtmosphereOverlay.material = _overlay
	if not Engine.is_editor_hint():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_start_heartbeat()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw = clampf(_yaw - event.relative.x * mouse_sensitivity, -0.8, 0.8)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -0.7, 0.65)
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_hands.yank()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _body:
		return
	var axis := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		axis = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_thrash = _thrash.lerp(axis, minf(delta * 8.0, 1.0))
	_body.velocity = Vector3.ZERO
	_body.position = Vector3(_thrash.x * 0.006, -0.18, 0.34 + _thrash.y * 0.006)
	_camera.rotation = Vector3(_pitch, _yaw, sin(_time * 13.0) * _thrash.length() * 0.009)
	_camera.position.y = 0.115 + sin(_time * 11.0) * _thrash.length() * 0.003
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	_hands.right_grasp = captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_hands.left_grasp = captured and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	_hands.thrash = _thrash


func _process(delta: float) -> void:
	if not _material:
		return
	if not Engine.is_editor_hint():
		_time += delta
	_material.set_shader_parameter("wetness", flesh_wetness)
	_material.set_shader_parameter("life", demon_life)
	_material.set_shader_parameter("phase", _time * 2.2)
	_update_restraints()
	if _overlay:
		_overlay.set_shader_parameter("blood_intensity", blood_screen_intensity)
	if Engine.is_editor_hint():
		return
	var closure := smoothstep(5.0, 14.0, _time) if seal_entrance else 0.0
	_seal.scale.y = lerpf(0.006, 0.095, closure)
	$ColdOpeningLight.light_energy = 0.09 * (1.0 - closure)
	var beat := pow(maxf(sin(_time * 2.2), 0.0), 4.0)
	$FleshGlow.light_energy = 0.18 + beat * 0.16
	$RearFleshGlow.light_energy = 0.09 + beat * 0.07
	$UI/LookHint.text = "Hold LMB / RMB: grasp   ·   E: yank   ·   WASD: struggle   ·   Mouse: look"
	$UI/LookHint.modulate.a = 0.7
	$UI/Whisper.text = _whisper_at(_time)
	if _heartbeat:
		_heartbeat.volume_db = lerpf(-38.0, heartbeat_volume_db, smoothstep(3.0, 10.0, _time))


func _make_tissue(tint: Color, scale_value: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/demon_mucosa.gdshader")
	material.set_shader_parameter("tissue_texture", preload("res://assets/textures/demon/gutsy.png"))
	material.set_shader_parameter("tissue_tint", tint)
	material.set_shader_parameter("texture_scale", scale_value)
	material.set_shader_parameter("wetness", flesh_wetness)
	return material


func _build_chamber() -> void:
	for child in $Interior.get_children():
		child.free()
	_material = _make_tissue(Color(0.48, 0.055, 0.065), 1.8)
	_floor_material = _make_tissue(Color(0.25, 0.025, 0.035), 2.7)
	_build_shell()
	# A continuous crawl bed, not loose spheres masquerading as knees or organs.
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(0.68, 0.045, 1.72)
	var floor_node := _mesh("CrawlBed", floor_mesh, _floor_material)
	floor_node.position = Vector3(0, FLOOR_Y - 0.0225, 0)
	_add_collision(floor_node)
	# Broad embedded folds follow the body's length, leaving the centre readable.
	for side in [-1.0, 1.0]:
		for fold in range(3):
			var points := PackedVector3Array()
			for step in range(33):
				var z := -0.85 + step / 32.0 * 1.7
				var angle := (0.18 + fold * 0.42) if side > 0 else PI - (0.18 + fold * 0.42)
				points.append(_wall_point(angle, z, 0.007))
			_tube("LongMucosalFold%d_%d" % [int(side), fold], points, 0.022, _material)
	# One focal end wall: a closed throat with thick, coherent petal folds.
	_lobe("ClosedThroat", Vector3(0, -0.005, -0.91), Vector3(0.35, 0.32, 0.105), _material)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.022, 0.012, 0.008)
	dark.roughness = 0.65
	_lobe("ThroatCrease", Vector3(0, -0.025, -0.799), Vector3(0.016, 0.115, 0.004), dark)
	for side in [-1.0, 1.0]:
		var lip := PackedVector3Array()
		for step in range(25):
			var t := step / 24.0
			lip.append(Vector3(side * (0.014 + sin(t * PI) * 0.09), -0.18 + t * 0.30, -0.80 - sin(t * PI) * 0.028))
		_tube("ThroatLip%d" % int(side), lip, 0.034, _material)
	_lobe("RearWall", Vector3(0, -0.005, 0.94), Vector3(0.35, 0.32, 0.07), _material)
	# Two broad lateral pads are fused to the lining, rather than floating props.
	_lobe("LeftMucosalPad", Vector3(-0.31, -0.12, -0.04), Vector3(0.11, 0.17, 0.33), _material)
	_lobe("RightMucosalPad", Vector3(0.31, -0.12, 0.03), Vector3(0.11, 0.17, 0.33), _material)
	_lobe("OverhangingLining", Vector3(0, 0.31, -0.13), Vector3(0.32, 0.07, 0.42), _material)
	var fluid := StandardMaterial3D.new()
	fluid.albedo_color = Color(0.075, 0.043, 0.012)
	fluid.roughness = 0.19
	fluid.metallic_specular = 0.35
	_lobe("ContactFluid", Vector3(-0.20, FLOOR_Y + 0.002, -0.35), Vector3(0.06, 0.003, 0.20), fluid)
	var seam := PackedVector3Array()
	for step in range(24):
		seam.append(_wall_point(-0.28, 0.20 + step / 23.0 * 0.43, 0.002))
	_tube("EntrySeam", seam, 0.024, _material)
	var seal_mesh := SphereMesh.new()
	seal_mesh.radius = 1.0
	seal_mesh.height = 2.0
	_seal = _mesh("EntranceMembrane", seal_mesh, _material)
	_seal.position = Vector3(0.418, -0.05, 0.42)
	_seal.scale = Vector3(0.02, 0.006, 0.24)
	_build_restraints()


func _build_restraints() -> void:
	_restraints.clear()
	for index in range(6):
		var points := PackedVector3Array([Vector3.ZERO, Vector3(0.01, 0, 0)])
		_restraints.append(_mesh("LivingRestraint%d" % index, _tube_mesh(points, 0.025), _material))
	# Broad belts press across the trapped body beneath the camera.
	for belt in range(2):
		var points := PackedVector3Array()
		for step in range(25):
			var t := step / 24.0
			points.append(Vector3(lerpf(-0.33, 0.33, t), -0.26 + sin(t * PI) * 0.14, 0.20 + belt * 0.27))
		_tube("TorsoRestraint%d" % belt, points, 0.038, _material)


func _update_restraints() -> void:
	if not _hands or _restraints.size() != 6:
		return
	for side in range(2):
		var right := side == 0
		var sign_value := 1.0 if right else -1.0
		var wrist: Vector3 = to_local(_hands.wrist_world(right))
		var cuff := PackedVector3Array()
		for step in range(33):
			var a := step / 32.0 * TAU
			cuff.append(wrist + Vector3(cos(a) * 0.037, sin(a) * 0.030, 0))
		_restraints[side * 3].mesh = _tube_mesh(cuff, 0.014)
		for tether in range(2):
			var anchor := Vector3(sign_value * 0.32, 0.24 if tether == 0 else -0.29, 0.16)
			var held_point: Vector3 = to_local(_hands.grip_world(right)) if tether == 0 else wrist
			var points := PackedVector3Array()
			for step in range(17):
				var t := step / 16.0
				var point := anchor.lerp(held_point, t)
				point.z -= sin(t * PI) * (0.035 - _hands.pull_strength * 0.025)
				points.append(point)
			_restraints[side * 3 + tether + 1].mesh = _tube_mesh(points, 0.026 - _hands.pull_strength * 0.005)


func _wall_point(angle: float, z: float, inset: float = 0.0) -> Vector3:
	var end_taper := 1.0 - 0.20 * pow(absf(z) / (cavity_dimensions.z * 0.5), 4.0)
	var folds := 1.0 + sin(angle * 6.0 + z * 1.5) * 0.018 + sin(z * 8.0) * 0.012
	var x := cos(angle) * (cavity_dimensions.x * 0.5 * end_taper * folds - inset)
	var y := maxf(FLOOR_Y, sin(angle) * (cavity_dimensions.y * 0.5 * folds - inset))
	return Vector3(x, y, z)


func _build_shell() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	const RINGS := 64
	const SIDES := 96
	for ring in range(RINGS + 1):
		var z := -cavity_dimensions.z * 0.5 + ring / float(RINGS) * cavity_dimensions.z
		for side in range(SIDES + 1):
			var angle := side / float(SIDES) * TAU
			var point := _wall_point(angle, z)
			vertices.append(point)
			normals.append(Vector3.UP if point.y <= FLOOR_Y + 0.001 else -Vector3(cos(angle), sin(angle), 0).normalized())
	for ring in range(RINGS):
		var z := -cavity_dimensions.z * 0.5 + (ring + 0.5) / float(RINGS) * cavity_dimensions.z
		for side in range(SIDES):
			var angle := (side + 0.5) / float(SIDES) * TAU
			# The crawl bed supplies this surface. Avoid coplanar shell/floor faces.
			if sin(angle) < -0.85:
				continue
			if z > 0.20 and z < 0.63 and angle > TAU - 0.28:
				continue
			var a := ring * (SIDES + 1) + side
			var b := a + SIDES + 1
			indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_add_collision(_mesh("ContinuousLining", mesh, _material))


func _add_collision(instance: MeshInstance3D) -> void:
	var solid := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = instance.mesh.create_trimesh_shape()
	solid.add_child(shape)
	instance.add_child(solid)


func _tube(label: String, points: PackedVector3Array, radius: float, material: Material) -> void:
	_mesh(label, _tube_mesh(points, radius), material)


func _tube_mesh(points: PackedVector3Array, radius: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 16
	for ring in range(points.size()):
		var tangent := (points[mini(ring + 1, points.size() - 1)] - points[maxi(0, ring - 1)]).normalized()
		var reference := Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var normal := tangent.cross(reference).normalized()
		var binormal := tangent.cross(normal).normalized()
		for side in range(SIDES):
			var angle := side / float(SIDES) * TAU
			var radial := normal * cos(angle) + binormal * sin(angle)
			surface.set_normal(radial)
			var taper := 0.45 + sin(ring / float(points.size() - 1) * PI) * 0.55
			surface.add_vertex(points[ring] + radial * radius * taper)
	for ring in range(points.size() - 1):
		for side in range(SIDES):
			var a := ring * SIDES + side
			var b := ring * SIDES + (side + 1) % SIDES
			for index in [a, a + SIDES, b, b, a + SIDES, b + SIDES]:
				surface.add_index(index)
	return surface.commit()


func _lobe(label: String, at: Vector3, radii: Vector3, material: Material) -> void:
	var shape := SphereMesh.new()
	shape.radius = 1.0
	shape.height = 2.0
	shape.radial_segments = 48
	shape.rings = 24
	var node := _mesh(label, shape, material)
	node.position = at
	node.scale = radii


func _mesh(label: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	$Interior.add_child(node)
	return node


func _start_heartbeat() -> void:
	var sound := load("res://assets/audio/demon/heartbeat_slow.wav") as AudioStreamWAV
	if not sound:
		return
	sound = sound.duplicate() as AudioStreamWAV
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_end = int(sound.get_length() * sound.mix_rate)
	_heartbeat = AudioStreamPlayer.new()
	_heartbeat.stream = sound
	_heartbeat.volume_db = -38.0
	add_child(_heartbeat)
	_heartbeat.play()


func _whisper_at(seconds: float) -> String:
	if seconds > 2.0 and seconds < 5.0:
		return "Be still. You are warm now."
	if seconds > 9.0 and seconds < 13.0:
		return "The cold cannot reach you here."
	return ""
