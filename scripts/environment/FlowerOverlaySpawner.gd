extends Node2D
class_name FlowerOverlaySpawner

@export var white_flower_textures: Array[Texture2D] = []
@export var pink_flower_textures: Array[Texture2D] = []
@export var flower_material: ShaderMaterial

@export var spawn_area: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))

@export var patch_candidate_spacing: int = 80
@export_range(0.0, 1.0, 0.01) var patch_spawn_chance: float = 0.26

@export var min_flowers_per_patch: int = 2
@export var max_flowers_per_patch: int = 5
@export var patch_radius: float = 26.0

@export_range(0.0, 1.0, 0.01) var pink_patch_chance: float = 0.22

@export var seed_value: int = 24680
@export var clear_before_spawn: bool = true

@export var blocked_rects: Array[Rect2] = []

@export var edge_bonus_enabled: bool = true
@export var edge_margin: float = 96.0
@export_range(0.0, 1.0, 0.01) var edge_patch_bonus: float = 0.12

@export var min_flower_distance: float = 18.0
@export var max_place_attempts_per_flower: int = 12

@export var patch_min_radius_ratio: float = 0.25

@export var patch_x_scale_min: float = 0.85
@export var patch_x_scale_max: float = 1.35
@export var patch_y_scale_min: float = 0.65
@export var patch_y_scale_max: float = 1.05

@export var patch_drift_strength: float = 8.0

@export_range(0.0, 1.0, 0.01) var subcluster_chance: float = 0.55
@export var subcluster_offset_ratio: float = 0.45

@export var enable_flower_shadow: bool = true

@export var shadow_offset: Vector2 = Vector2(2, 3)
@export_range(0.0, 1.0, 0.01) var shadow_alpha: float = 0.22
@export var shadow_scale: Vector2 = Vector2(1.0, 0.45)

@export var shadow_color: Color = Color(0.18, 0.22, 0.10, 1.0)



func _ready() -> void:
	spawn_flower_patches()


func spawn_flower_patches() -> void:
	if white_flower_textures.is_empty() and pink_flower_textures.is_empty():
		push_warning("FlowerOverlaySpawner: no flower textures assigned.")
		return

	if clear_before_spawn:
		clear_existing_flowers()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	for y in range(start_y, end_y, patch_candidate_spacing):
		for x in range(start_x, end_x, patch_candidate_spacing):
			var patch_center := Vector2(x, y)

			if is_blocked_position(patch_center):
				continue

			var chance := get_patch_spawn_chance(patch_center)

			if rng.randf() > chance:
				continue

			var use_pink := should_create_pink_patch(rng)
			create_flower_patch(patch_center, rng, use_pink)


func should_create_pink_patch(rng: RandomNumberGenerator) -> bool:
	if pink_flower_textures.is_empty():
		return false

	if white_flower_textures.is_empty():
		return true

	return rng.randf() < pink_patch_chance


func create_flower_patch(center_pos: Vector2, rng: RandomNumberGenerator, use_pink: bool) -> void:
	var count := rng.randi_range(min_flowers_per_patch, max_flowers_per_patch)

	if use_pink:
		count = max(1, count - 1)

	var placed_positions: Array[Vector2] = []

	# 패치 전체 성격
	var patch_rotation := rng.randf_range(0.0, TAU)
	var patch_x_scale := rng.randf_range(patch_x_scale_min, patch_x_scale_max)
	var patch_y_scale := rng.randf_range(patch_y_scale_min, patch_y_scale_max)

	# 패치가 한쪽으로 살짝 흐르는 방향
	var drift_angle := rng.randf_range(0.0, TAU)
	var drift_dir := Vector2(cos(drift_angle), sin(drift_angle))
	var drift_strength := rng.randf_range(0.4, 1.0) * patch_drift_strength

	# 서브 군집 여부
	var use_subcluster := rng.randf() < subcluster_chance
	var subcluster_center := center_pos

	if use_subcluster:
		var sub_angle := rng.randf_range(0.0, TAU)
		var sub_distance := patch_radius * subcluster_offset_ratio
		subcluster_center = center_pos + Vector2(cos(sub_angle), sin(sub_angle)) * sub_distance

	for i in range(count):
		var use_secondary_center := use_subcluster and i >= int(count / 2)
		var active_center := subcluster_center if use_secondary_center else center_pos

		var flower_pos := find_valid_flower_position_shaped(
			active_center,
			placed_positions,
			rng,
			patch_rotation,
			patch_x_scale,
			patch_y_scale,
			drift_dir,
			drift_strength
		)

		if flower_pos == Vector2.INF:
			continue

		placed_positions.append(flower_pos)
		create_flower(flower_pos, rng, use_pink)


func create_flower(pos: Vector2, rng: RandomNumberGenerator, use_pink: bool) -> void:
	var texture_pool := pink_flower_textures if use_pink else white_flower_textures

	if texture_pool.is_empty():
		texture_pool = white_flower_textures if not white_flower_textures.is_empty() else pink_flower_textures

	if texture_pool.is_empty():
		return

	var texture_index := rng.randi_range(0, texture_pool.size() - 1)
	var texture := texture_pool[texture_index]

	var root := Node2D.new()
	root.add_to_group("farm_clearable_vegetation")
	root.position = pos
	root.z_index = 0
	add_child(root)

	if enable_flower_shadow:
		var shadow := Sprite2D.new()
		shadow.name = "ShadowSprite"
		shadow.texture = texture
		shadow.centered = true
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow.position = shadow_offset
		shadow.scale = shadow_scale
		shadow.modulate = Color(
			shadow_color.r,
			shadow_color.g,
			shadow_color.b,
			shadow_alpha
		)
		shadow.z_index = -1
		root.add_child(shadow)

	var sprite := Sprite2D.new()
	sprite.name = "FlowerSprite"
	sprite.texture = texture
	sprite.centered = true
	sprite.flip_h = rng.randf() < 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 0
	root.add_child(sprite)

	if flower_material != null:
		sprite.material = flower_material
		sprite.set_instance_shader_parameter("wind_phase", rng.randf_range(0.0, TAU))

		if use_pink:
			sprite.set_instance_shader_parameter("wind_scale", rng.randf_range(0.45, 0.75))
		else:
			sprite.set_instance_shader_parameter("wind_scale", rng.randf_range(0.55, 0.95))


func clear_existing_flowers() -> void:
	for child in get_children():
		child.queue_free()


func is_blocked_position(pos: Vector2) -> bool:
	for rect in blocked_rects:
		if rect.has_point(pos):
			return true

	if is_inside_vegetation_spawn_blocker(pos):
		return true

	return false


func is_inside_vegetation_spawn_blocker(pos: Vector2) -> bool:
	var world_pos := to_global(pos)
	var blockers := get_tree().get_nodes_in_group("vegetation_spawn_blocker")

	for blocker in blockers:
		if blocker is Area2D == false:
			continue

		var blocker_area := blocker as Area2D

		for shape_owner_id in blocker_area.get_shape_owners():
			var owner_transform: Transform2D = blocker_area.shape_owner_get_transform(shape_owner_id)
			var shape_count: int = blocker_area.shape_owner_get_shape_count(shape_owner_id)

			for i in range(shape_count):
				var shape := blocker_area.shape_owner_get_shape(shape_owner_id, i)

				if shape is RectangleShape2D:
					var rectangle_shape := shape as RectangleShape2D
					var global_center: Vector2 = blocker_area.global_transform * owner_transform.origin
					var rect := Rect2(
						global_center - rectangle_shape.size / 2.0,
						rectangle_shape.size
					)

					if rect.has_point(world_pos):
						return true

	return false


func get_patch_spawn_chance(pos: Vector2) -> float:
	var chance := patch_spawn_chance

	if edge_bonus_enabled and is_near_spawn_area_edge(pos):
		chance += edge_patch_bonus

	return clamp(chance, 0.0, 1.0)


func is_near_spawn_area_edge(pos: Vector2) -> bool:
	var left := spawn_area.position.x
	var top := spawn_area.position.y
	var right := spawn_area.position.x + spawn_area.size.x
	var bottom := spawn_area.position.y + spawn_area.size.y

	if pos.x < left + edge_margin:
		return true
	if pos.x > right - edge_margin:
		return true
	if pos.y < top + edge_margin:
		return true
	if pos.y > bottom - edge_margin:
		return true

	return false


func find_valid_flower_position(center_pos: Vector2, placed_positions: Array[Vector2], rng: RandomNumberGenerator) -> Vector2:
	for attempt in range(max_place_attempts_per_flower):
		var angle := rng.randf_range(0.0, TAU)

		# 너무 중심에 몰리지 않게 최소 반경을 조금 둠
		var min_radius := patch_radius * 0.25
		var distance := rng.randf_range(min_radius, patch_radius)

		var offset := Vector2(cos(angle), sin(angle)) * distance
		var candidate_pos := center_pos + offset

		if is_blocked_position(candidate_pos):
			continue

		if is_too_close_to_existing_flowers(candidate_pos, placed_positions):
			continue

		return candidate_pos

	return Vector2.INF


func is_too_close_to_existing_flowers(pos: Vector2, placed_positions: Array[Vector2]) -> bool:
	for existing_pos in placed_positions:
		if pos.distance_to(existing_pos) < min_flower_distance:
			return true

	return false


func find_valid_flower_position_shaped(
	center_pos: Vector2,
	placed_positions: Array[Vector2],
	rng: RandomNumberGenerator,
	patch_rotation: float,
	patch_x_scale: float,
	patch_y_scale: float,
	drift_dir: Vector2,
	drift_strength: float
) -> Vector2:
	for attempt in range(max_place_attempts_per_flower):
		var angle := rng.randf_range(0.0, TAU)

		var min_radius := patch_radius * patch_min_radius_ratio
		var distance := rng.randf_range(min_radius, patch_radius)

		# 기본 원형 오프셋
		var local_offset := Vector2(cos(angle), sin(angle)) * distance

		# 타원형 스케일
		local_offset.x *= patch_x_scale
		local_offset.y *= patch_y_scale

		# 회전 적용
		local_offset = local_offset.rotated(patch_rotation)

		# 중심에서 멀수록 한쪽으로 조금 더 흐르게
		var drift_weight := distance / patch_radius
		local_offset += drift_dir * drift_strength * drift_weight

		# 약한 랜덤 왜곡
		local_offset += Vector2(
			rng.randf_range(-3.0, 3.0),
			rng.randf_range(-3.0, 3.0)
		)

		var candidate_pos := center_pos + local_offset

		if is_blocked_position(candidate_pos):
			continue

		if is_too_close_to_existing_flowers(candidate_pos, placed_positions):
			continue

		return candidate_pos

	return Vector2.INF
