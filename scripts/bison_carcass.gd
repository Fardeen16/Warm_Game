@tool
class_name BisonCarcass
extends Node3D
## Dead wood bison lying on its side. Stand at its belly (CutZone) and hold E: the player
## kneels and slices it open with the knife, from the hind belly up to the neck. Then press E
## to crawl inside, which loads the inside_scene.
## Built from placeholder CSG shapes; swap the Body for a real model later.

signal opened
signal entered

## Toggle in the inspector to preview the opened carcass.
@export var is_cut_open: bool = false:
	set(value):
		is_cut_open = value
		_cut_progress = 1.0 if value else 0.0
		_update_cut()
## Seconds of holding E to cut it open.
@export_range(0.2, 20.0, 0.1) var cut_duration: float = 3.0
## Scene loaded once the player has crawled inside.
@export_file("*.tscn") var inside_scene: String = "res://scenes/inside_carcass.tscn"

var _cut_progress := 0.0
# Full cut along the body's length, from the Opening box (x from the hind end to the neck).
var _cut_start_x := 0.0
var _cut_length := 0.0
var _player_in_reach: Node3D
var _entered := false

@onready var _cavity: CSGShape3D = $Body/Cavity
@onready var _opening: CSGShape3D = $Body/Opening
@onready var _entry_point: Marker3D = $EntryPoint
@onready var _hide_point: Marker3D = $HidePoint
@onready var _kneel_point: Marker3D = $KneelPoint


func _ready() -> void:
	add_to_group("interactable")
	_cut_length = (_opening as CSGBox3D).size.x
	_cut_start_x = _opening.position.x - _cut_length * 0.5
	var cut_zone: Area3D = $CutZone
	cut_zone.body_entered.connect(_on_cut_zone_body_entered)
	cut_zone.body_exited.connect(_on_cut_zone_body_exited)
	_update_cut()


func can_interact(player: Node3D) -> bool:
	return player == _player_in_reach and not _entered


func get_prompt() -> String:
	return "Press E to crawl inside" if is_cut_open else "Hold E to cut it open"


## Once it's open, stay kneeling at the opening, ready to crawl in.
func keep_kneeling() -> bool:
	return is_cut_open


func get_progress() -> float:
	return -1.0 if is_cut_open else _cut_progress


func interact(player: Node3D, delta: float, just_pressed: bool) -> void:
	if not is_cut_open:
		player.kneel_at(_kneel_point)
		# Only cut once the player is down on their knees at the belly.
		if player.is_kneeling():
			_cut_progress = minf(_cut_progress + delta / cut_duration, 1.0)
			_update_cut()
			if _cut_progress >= 1.0:
				is_cut_open = true
				opened.emit()
		player.show_cut(_cut_point())
	elif just_pressed and player.has_method("enter_shelter"):
		_entered = true
		player.enter_shelter(_entry_point, _hide_point, _on_player_inside)


## Where the knife is: the end of the cut so far, on the surface of the belly.
func _cut_point() -> Vector3:
	var x := _cut_start_x + _cut_length * _cut_progress
	# The belly is rounded, so the surface sits further in toward the ends of the body.
	var z := -0.7 * sqrt(maxf(0.0, 1.0 - pow(x / 1.3, 2.0)))
	return to_global(Vector3(x, _opening.position.y, z))


func _on_player_inside() -> void:
	entered.emit()
	if inside_scene != "":
		get_tree().change_scene_to_file(inside_scene)


func _on_cut_zone_body_entered(body: Node3D) -> void:
	if body.has_method("enter_shelter"):
		_player_in_reach = body


func _on_cut_zone_body_exited(body: Node3D) -> void:
	if body == _player_in_reach:
		_player_in_reach = null


func _update_cut() -> void:
	if not is_node_ready():
		return
	# Hidden CSG children are left out of the combined shape, so this closes the body up.
	# The slit runs from the hind end toward the neck, widening as the cut goes on.
	_cavity.visible = _cut_progress > 0.0
	_opening.visible = _cut_progress > 0.02
	# Closed or fully open both use the full-size box, so the saved scene never changes.
	var length := _cut_progress if _cut_progress > 0.02 and _cut_progress < 1.0 else 1.0
	_opening.scale = Vector3(length, lerpf(0.15, 1.0, length), 1.0)
	if _cut_length > 0.0:
		_opening.position.x = _cut_start_x + _cut_length * length * 0.5
