extends Node2D

@export var front_wall_root_path: NodePath = NodePath("FrontWallRoot")
@export var front_occlusion_area_path: NodePath = NodePath("FrontOcclusionArea")
@export var interaction_point_path: NodePath = NodePath("InteractionPoint")

@export var normal_alpha: float = 1.0
@export var occluded_alpha: float = 0.35

var front_wall_root: CanvasItem
var front_occlusion_area: Area2D
var player_inside_front_occlusion: bool = false


func _ready() -> void:
	front_wall_root = get_node_or_null(front_wall_root_path) as CanvasItem
	front_occlusion_area = get_node_or_null(front_occlusion_area_path) as Area2D

	if front_occlusion_area:
		front_occlusion_area.body_entered.connect(_on_front_occlusion_body_entered)
		front_occlusion_area.body_exited.connect(_on_front_occlusion_body_exited)

	_set_front_wall_alpha(normal_alpha)


func _on_front_occlusion_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_inside_front_occlusion = true
	_set_front_wall_alpha(occluded_alpha)


func _on_front_occlusion_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_inside_front_occlusion = false
	_set_front_wall_alpha(normal_alpha)


func _set_front_wall_alpha(alpha: float) -> void:
	if not front_wall_root:
		return

	front_wall_root.modulate.a = alpha
