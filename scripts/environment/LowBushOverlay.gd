extends Area2D
class_name LowBushOverlay

@export var rustle_cooldown: float = 0.45
@export var squash_x_scale: float = 1.16
@export var squash_y_scale: float = 0.76
@export var squash_time: float = 0.06
@export var recover_time: float = 0.18
@export var squash_rotation_degrees: float = 10.5

@export var random_pitch_min: float = 0.92
@export var random_pitch_max: float = 1.08

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


var can_rustle: bool = true
var original_scale: Vector2


func _ready() -> void:
	original_scale = sprite.scale

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func setup(texture: Texture2D, material_override: ShaderMaterial = null, flip_h: bool = false) -> void:
	if sprite == null:
		sprite = $Sprite2D

	sprite.texture = texture
	sprite.flip_h = flip_h
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if material_override != null:
		sprite.material = material_override


func _on_body_entered(body: Node) -> void:
	if not can_rustle:
		return

	if not body.is_in_group("player"):
		return

	rustle()


func rustle() -> void:
	can_rustle = false

	play_rustle_sound()
	play_squash_animation()

	await get_tree().create_timer(rustle_cooldown).timeout
	can_rustle = true


func play_rustle_sound() -> void:
	if audio_player == null:
		return

	if audio_player.stream == null:
		return

	audio_player.pitch_scale = randf_range(random_pitch_min, random_pitch_max)
	audio_player.play()


func play_squash_animation() -> void:
	if sprite == null:
		return

	var original_rotation := sprite.rotation
	var target_rotation := deg_to_rad(randf_range(-squash_rotation_degrees, squash_rotation_degrees))

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(original_scale.x * squash_x_scale, original_scale.y * squash_y_scale),
		squash_time
	)

	tween.tween_property(
		sprite,
		"rotation",
		target_rotation,
		squash_time
	)

	tween.set_parallel(false)

	tween.tween_property(
		sprite,
		"scale",
		original_scale,
		recover_time
	)

	tween.parallel().tween_property(
		sprite,
		"rotation",
		original_rotation,
		recover_time
	)
