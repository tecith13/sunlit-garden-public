extends Node2D
class_name GrassColorPatchSpawner

@export var patch_textures: Array[Texture2D] = []

@export var spawn_area: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))

@export var candidate_spacing: int = 128
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.35

@export var random_offset: int = 48
@export var seed_value: int = 13579
@export var clear_before_spawn: bool = true

@export var blocked_rects: Array[Rect2] = []

# 패치가 너무 진하면 바로 얼룩처럼 보이므로 낮게 시작
@export_range(0.0, 1.0, 0.01) var alpha_min: float = 0.18
@export_range(0.0, 1.0, 0.01) var alpha_max: float = 0.32

# 픽셀아트라 자유 스케일은 최소화. 그래도 색면 패치는 약간 허용 가능.
@export_range(0.5, 2.0, 0.05) var scale_min: float = 0.9
@export_range(0.5, 2.0, 0.05) var scale_max: float = 1.15

@export var allow_flip_h: bool = true
@export var allow_flip_v: bool = true

# 중앙은 조금 덜, 가장자리는 조금 더 자연스럽게
@export var edge_bonus_enabled: bool = true
@export var edge_margin: float = 128.0
@export_range(0.0, 1.0, 0.01) var edge_spawn_bonus: float = 0.12

# 너무 가까이 겹치지 않게. 색면은 약간 겹쳐도 괜찮음.
@export var min_patch_distance: float = 80.0
@export var max_place_attempts: int = 8

var placed_positions: Array[Vector2] = []


func _ready() -> void:
	spawn_color_patches()


func spawn_color_patches() -> void:
	if patch_textures.is_empty():
		push_warning("GrassColorPatchSpawner: patch_textures is empty.")
		return

	if clear_before_spawn:
		clear_existing_patches()

	placed_positions.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	var created_count := 0

	for y in range(start_y, end_y, candidate_spacing):
		for x in range(start_x, end_x, candidate_spacing):
			var base_pos := Vector2(x, y)

			if is_blocked_position(base_pos):
				continue

			var chance := get_spawn_chance_for_position(base_pos)

			if rng.randf() > chance:
				continue

			var patch_pos := find_valid_patch_position(base_pos, rng)

			if patch_pos == Vector2.INF:
				continue

			create_patch(patch_pos, rng)
			placed_positions.append(patch_pos)
			created_count += 1

	print("GrassColorPatchSpawner created patches: ", created_count)


func find_valid_patch_position(base_pos: Vector2, rng: RandomNumberGenerator) -> Vector2:
	for attempt in range(max_place_attempts):
		var offset := Vector2(
			rng.randi_range(-random_offset, random_offset),
			rng.randi_range(-random_offset, random_offset)
		)

		var candidate_pos := base_pos + offset

		if is_blocked_position(candidate_pos):
			continue

		if is_too_close_to_existing_patches(candidate_pos):
			continue

		return candidate_pos

	return Vector2.INF


func create_patch(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()

	var texture_index := rng.randi_range(0, patch_textures.size() - 1)
	sprite.texture = patch_textures[texture_index]

	sprite.position = pos
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	if allow_flip_h:
		sprite.flip_h = rng.randf() < 0.5

	if allow_flip_v:
		sprite.flip_v = rng.randf() < 0.5

	var random_scale := rng.randf_range(scale_min, scale_max)
	sprite.scale = Vector2(random_scale, random_scale)

	var alpha := rng.randf_range(alpha_min, alpha_max)
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)

	# GrassColorPatches 부모 자체가 grass tuft보다 아래에 있으므로 여기서는 0
	sprite.z_index = 0

	add_child(sprite)


func clear_existing_patches() -> void:
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


func is_too_close_to_existing_patches(pos: Vector2) -> bool:
	for existing_pos in placed_positions:
		if pos.distance_to(existing_pos) < min_patch_distance:
			return true

	return false


func get_spawn_chance_for_position(pos: Vector2) -> float:
	var chance := spawn_chance

	if edge_bonus_enabled and is_near_spawn_area_edge(pos):
		chance += edge_spawn_bonus

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
