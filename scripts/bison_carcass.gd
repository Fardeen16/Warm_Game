@tool
class_name BisonCarcass
extends Node3D
## Dead wood bison lying on its side. Call cut_open() to slice the belly open, revealing
## a hollow body cavity big enough for the player to curl up inside (see HidePoint).
## Built from placeholder CSG shapes; swap the Body for a real model later.

signal opened

## Toggle in the inspector to preview the opened carcass.
@export var is_cut_open: bool = false:
	set(value):
		is_cut_open = value
		_update_cut()

@onready var _cavity: CSGShape3D = $Body/Cavity
@onready var _opening: CSGShape3D = $Body/Opening


func _ready() -> void:
	_update_cut()


func cut_open() -> void:
	if is_cut_open:
		return
	is_cut_open = true
	opened.emit()


func _update_cut() -> void:
	if not is_node_ready():
		return
	# Hidden CSG children are left out of the combined shape, so this closes the body up.
	_cavity.visible = is_cut_open
	_opening.visible = is_cut_open
