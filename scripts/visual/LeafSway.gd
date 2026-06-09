extends Node2D

@export var sway_rotation_degrees: float = 0.8
@export var sway_position_x: float = 1.0
@export var sway_speed: float = 0.8
@export var randomize_phase: bool = true

var base_rotation: float
var base_position: Vector2
var sway_phase: float = 0.0

func _ready() -> void:
	base_rotation = rotation
	base_position = position

	if randomize_phase:
		sway_phase = randf() * TAU

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var wave := sin(t * sway_speed + sway_phase)

	rotation = base_rotation + deg_to_rad(wave * sway_rotation_degrees)
	position.x = base_position.x + wave * sway_position_x
