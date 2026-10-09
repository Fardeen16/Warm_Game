class_name Player
extends CharacterBody3D
## Simple first-person controller: WASD / arrows to move, Space to jump, mouse to look,
## E to interact with whatever you are looking at (nodes in the "interactable" group).
## Esc frees the mouse, click to capture it again.

## Prompt text and hold progress (-1 when there is no progress bar) for the HUD.
signal interaction_changed(prompt: String, progress: float)
## The crawl into shelter has started and will take this many seconds.
signal entering_shelter(duration: float)

@export var move_speed: float = 5.0
@export var acceleration: float = 12.0
@export var air_control: float = 0.3
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
## How far away you can interact with things (m).
@export var reach: float = 3.0

var controls_enabled := true
# Kept while E is held, so looking into the cut you are making doesn't drop it.
var _held_target: Node

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var _interact_ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_interact_ray.target_position = Vector3.FORWARD * reach
	_interact_ray.add_exception(self)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if controls_enabled:
			rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clampf(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input := Vector2.ZERO
	if controls_enabled:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var target := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized() * move_speed
	var accel := acceleration if is_on_floor() else acceleration * air_control
	velocity.x = move_toward(velocity.x, target.x, accel * move_speed * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * move_speed * delta)

	move_and_slide()

	if controls_enabled:
		_update_interaction(delta)


func _update_interaction(delta: float) -> void:
	var target := _find_interactable()
	if Input.is_action_pressed("interact"):
		if _held_target and is_instance_valid(_held_target) and _held_target.can_interact(self):
			target = _held_target
		_held_target = target
	else:
		_held_target = null
	if target == null:
		interaction_changed.emit("", -1.0)
		return
	if Input.is_action_pressed("interact"):
		target.interact(self, delta, Input.is_action_just_pressed("interact"))
	if controls_enabled:
		interaction_changed.emit(target.get_prompt(), target.get_progress())


func _find_interactable() -> Node:
	if not _interact_ray.is_colliding():
		return null
	var node := _interact_ray.get_collider() as Node
	while node and not node.is_in_group("interactable"):
		node = node.get_parent()
	if node and node.can_interact(self):
		return node
	return null


## Crouches down at entry, then crawls to inside, and calls on_inside when done.
func enter_shelter(entry: Node3D, inside: Node3D, on_inside: Callable) -> void:
	const CROUCH_TIME := 1.4
	const CRAWL_TIME := 1.6
	controls_enabled = false
	interaction_changed.emit("", -1.0)
	entering_shelter.emit(CROUCH_TIME + CRAWL_TIME)

	# Detach the camera from the body so it can move freely through the animation.
	var start := camera.global_transform
	camera.top_level = true
	camera.global_transform = start

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_move_camera.bind(start, entry.global_transform), 0.0, 1.0, CROUCH_TIME)
	tween.tween_method(_move_camera.bind(entry.global_transform, inside.global_transform), 0.0, 1.0, CRAWL_TIME)
	tween.tween_callback(on_inside)


func _move_camera(weight: float, from: Transform3D, to: Transform3D) -> void:
	# interpolate_with turns smoothly instead of skewing like a plain lerp.
	camera.global_transform = from.interpolate_with(to, weight)


func die() -> void:
	controls_enabled = false
	interaction_changed.emit("", -1.0)
