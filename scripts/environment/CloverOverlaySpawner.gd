extends Node2D
class_name CloverOverlaySpawner

@export var clover_textures: Array[Texture2D] = []

@export var spawn_area: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))
@export var blocked_rects: Array[Rect2] = []

@export var clear_before_spawn: bool = true
@export var seed_value: int = 97531

# 군집 중심 후보
@export var cluster_center_spacing: int = 160
@export_range(0.0, 1.0, 0.01) var cluster_spawn_chance: float = 0.28
@export var cluster_random_offset: int = 36

# 군집 하나당 생성 수
@export var patches_per_cluster_min: int = 1
@export var patches_per_cluster_max: int = 2

# 군집 반경
@export var cluster_radius_min: float = 18.0
@export var cluster_radius_max: float = 40.0

# stray 소량
@export var stray_candidate_spacing: int = 192
@export_range(0.0, 1.0, 0.01) var stray_spawn_chance: float = 0.04
@export var stray_random_offset: int = 20

# 시각 변형
@export_range(0.5, 2.0, 0.05) var scale_min: float = 0.85
@export_range(0.5, 2.0, 0.05) var scale_max: float = 1.15

@export_range(0.0, 1.0, 0.01) var alpha_min: float = 0.82
@export_range(0.0, 1.0, 0.01) var alpha_max: float = 1.0

@export var allow_flip_h: bool = true
@export var allow_flip_v: bool = false

@export var min_patch_distance: float = 18.0
@export var max_place_attempts: int = 8

var placed_positions: Array[Vector2] = []


func _ready() -> void:
	spawn_clovers()


func spawn_clovers() -> void:
	if clover_textures.is_empty():
		push_warning("CloverOverlaySpawner: clover_textures is empty.")
		return

	if clear_before_spawn:
		clear_existing_clovers()

	placed_positions.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	spawn_clusters(rng)
	spawn_stray_clovers(rng)

	print("CloverOverlaySpawner created clovers: ", placed_positions.size())


func spawn_clusters(rng: RandomNumberGenerator) -> void:
	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	for y in range(start_y, end_y, cluster_center_spacing):
		for x in range(start_x, end_x, cluster_center_spacing):
			if rng.randf() > cluster_spawn_chance:
				continue

			var center := Vector2(x, y) + Vector2(
				rng.randi_range(-cluster_random_offset, cluster_random_offset),
				rng.randi_range(-cluster_random_offset, cluster_random_offset)
			)

			if is_blocked_position(center):
				continue

			create_cluster(center, rng)


func create_cluster(center: Vector2, rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(patches_per_cluster_min, patches_per_cluster_max)
	var radius := rng.randf_range(cluster_radius_min, cluster_radius_max)

	for i in range(count):
		for attempt in range(max_place_attempts):
			var angle := rng.randf_range(0.0, TAU)
			var dist := radius * pow(rng.randf(), 1.6)

			var pos := center + Vector2.RIGHT.rotated(angle) * dist
			pos += Vector2(
				rng.randi_range(-4, 4),
				rng.randi_range(-4, 4)
			)

			if is_blocked_position(pos):
				continue

			if is_too_close_to_existing(pos):
				continue

			create_clover_sprite(pos, rng)
			placed_positions.append(pos)
			break


func spawn_stray_clovers(rng: RandomNumberGenerator) -> void:
	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	for y in range(start_y, end_y, stray_candidate_spacing):
		for x in range(start_x, end_x, stray_candidate_spacing):
			if rng.randf() > stray_spawn_chance:
				continue

			var pos := Vector2(x, y) + Vector2(
				rng.randi_range(-stray_random_offset, stray_random_offset),
				rng.randi_range(-stray_random_offset, stray_random_offset)
			)

			if is_blocked_position(pos):
				continue

			if is_too_close_to_existing(pos):
				continue

			create_clover_sprite(pos, rng)
			placed_positions.append(pos)


func create_clover_sprite(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.add_to_group("farm_clearable_vegetation")

	var texture_index := rng.randi_range(0, clover_textures.size() - 1)
	sprite.texture = clover_textures[texture_index]
	sprite.position = pos
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 0

	if allow_flip_h:
		sprite.flip_h = rng.randf() < 0.5

	if allow_flip_v:
		sprite.flip_v = rng.randf() < 0.5

	var scale_value := rng.randf_range(scale_min, scale_max)
	sprite.scale = Vector2(scale_value, scale_value)

	var alpha_value := rng.randf_range(alpha_min, alpha_max)
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha_value)
	
	var tint := Color(0.82, 0.80, 0.38, alpha_value)
	sprite.modulate = tint

	add_child(sprite)


func clear_existing_clovers() -> void:
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


func is_too_close_to_existing(pos: Vector2) -> bool:
	for existing_pos in placed_positions:
		if pos.distance_to(existing_pos) < min_patch_distance:
			return true
	return false
