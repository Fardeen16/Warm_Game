class_name RopeGrab
extends StaticBody3D
## The bottom of the helicopter's rope: look at it up close and press E to grab on.
## Sits on collision layer 2 so the player can see it with the interact ray but walks
## through it instead of bumping into it.

signal grabbed

var helicopter: Helicopter
## Only grabbable once the rope is all the way down.
var enabled := false


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 2
	collision_mask = 0


func _process(_delta: float) -> void:
	if helicopter:
		global_position = helicopter.rope_end()


func can_interact(player: Node3D) -> bool:
	return enabled and player.global_position.distance_to(global_position) < 2.5


func get_prompt() -> String:
	return "Press E to grab the rope"


func get_progress() -> float:
	return -1.0


func interact(_player: Node3D, _delta: float, just_pressed: bool) -> void:
	if just_pressed and enabled:
		enabled = false
		grabbed.emit()
