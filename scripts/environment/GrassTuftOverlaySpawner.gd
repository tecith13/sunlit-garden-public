extends Node2D
class_name GrassTuftOverlaySpawner

@export var tuft_textures: Array[Texture2D] = []
@export var tuft_material: ShaderMaterial

@export var spawn_area: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))
@export var blocked_rects: Array[Rect2] = []

@export var clear_before_spawn: bool = true
@export var seed_value: int = 24680

# -----------------------------------
# Cluster settings
# -----------------------------------
@export var cluster_center_spacing: int = 128
@export_range(0.0, 1.0, 0.01) var cluster_spawn_chance: float = 0.35
@export var cluster_random_offset: int = 32

@export var tufts_per_cluster_min: int = 5
@export var tufts_per_cluster_max: int = 12

@export var cluster_radius_min: float = 22.0
@export var cluster_radius_max: float = 52.0

# -----------------------------------
# Stray settings
# -----------------------------------
@export var stray_candidate_spacing: int = 64
@export_range(0.0, 1.0, 0.01) var stray_spawn_chance: float = 0.06
@export var stray_random_offset: int = 12

# -----------------------------------
# Visual variation
# -----------------------------------
@export_range(0.5, 2.0, 0.05) var scale_min: float = 0.9
@export_range(0.5, 2.0, 0.05) var scale_max: float = 1.1

@export var allow_flip_h: bool = true
@export var allow_flip_v: bool = false

# -----------------------------------
# Placement control
# -----------------------------------
@export var min_tuft_distance: float = 10.0
@export var max_place_attempts: int = 8

var placed_positions: Array[Vector2] = []


func _ready() -> void:
	spawn_tufts()


func spawn_tufts() -> void:
	if tuft_textures.is_empty():
		push_warning("GrassTuftOverlaySpawner: tuft_textures is empty.")
		return

	if clear_before_spawn:
		clear_existing_tufts()

	placed_positions.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	spawn_clusters(rng)
	spawn_stray_tufts(rng)

	print("GrassTuftOverlaySpawner created tufts: ", placed_positions.size())


func spawn_clusters(rng: RandomNumberGenerator) -> void:
	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	for y in range(start_y, end_y, cluster_center_spacing):
		for x in range(start_x, end_x, cluster_center_spacing):
			var base_pos := Vector2(x, y)

			if rng.randf() > cluster_spawn_chance:
				continue

			var center := base_pos + Vector2(
				rng.randi_range(-cluster_random_offset, cluster_random_offset),
				rng.randi_range(-cluster_random_offset, cluster_random_offset)
			)

			if is_blocked_position(center):
				continue

			create_cluster(center, rng)


func create_cluster(center: Vector2, rng: RandomNumberGenerator) -> void:
	var tuft_count := rng.randi_range(tufts_per_cluster_min, tufts_per_cluster_max)
	var cluster_radius := rng.randf_range(cluster_radius_min, cluster_radius_max)

	for i in range(tuft_count):
		var placed := false

		for attempt in range(max_place_attempts):
			var angle := rng.randf_range(0.0, TAU)

			# 중심 쪽으로 조금 더 몰리게
			var dist := cluster_radius * pow(rng.randf(), 1.8)

			var offset := Vector2.RIGHT.rotated(angle) * dist
			offset += Vector2(
				rng.randi_range(-4, 4),
				rng.randi_range(-4, 4)
			)

			var pos := center + offset

			if is_blocked_position(pos):
				continue

			if is_too_close_to_existing(pos):
				continue

			create_tuft(pos, rng)
			placed_positions.append(pos)
			placed = true
			break

		if not placed:
			continue


func spawn_stray_tufts(rng: RandomNumberGenerator) -> void:
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

			create_tuft(pos, rng)
			placed_positions.append(pos)


func create_tuft(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var sprite := Sprite2D.new()
	sprite.add_to_group("farm_clearable_vegetation")

	var texture_index := rng.randi_range(0, tuft_textures.size() - 1)
	sprite.texture = tuft_textures[texture_index]
	sprite.position = pos
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 0

	if allow_flip_h:
		sprite.flip_h = rng.randf() < 0.5

	if allow_flip_v:
		sprite.flip_v = rng.randf() < 0.5

	var random_scale := rng.randf_range(scale_min, scale_max)
	sprite.scale = Vector2(random_scale, random_scale)

	if tuft_material != null:
		sprite.material = tuft_material
		sprite.set_instance_shader_parameter("wind_phase", rng.randf_range(0.0, TAU))
		sprite.set_instance_shader_parameter("wind_scale", rng.randf_range(0.5, 1.0))

	add_child(sprite)


func clear_existing_tufts() -> void:
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
		if pos.distance_to(existing_pos) < min_tuft_distance:
			return true
	return false
