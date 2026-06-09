extends Node2D
class_name BushOverlaySpawner

@export var low_bush_scene: PackedScene
@export var bush_textures: Array[Texture2D] = []
@export var bush_material: ShaderMaterial

@export var spawn_area: Rect2 = Rect2(Vector2(-512, -512), Vector2(1024, 1024))

@export var candidate_spacing: int = 96
@export_range(0.0, 1.0, 0.01) var spawn_chance: float = 0.16

@export var random_offset: int = 16
@export var seed_value: int = 97531
@export var clear_before_spawn: bool = true

@export var blocked_rects: Array[Rect2] = []

# 덤불은 중앙보다 가장자리/벽 아래 쪽에 많게
@export var edge_bonus_enabled: bool = true
@export var edge_margin: float = 128.0
@export_range(0.0, 1.0, 0.01) var edge_spawn_bonus: float = 0.20

# 덤불끼리 너무 붙는 것 방지
@export var min_bush_distance: float = 48.0
@export var max_place_attempts: int = 8

var placed_positions: Array[Vector2] = []


func _ready() -> void:
	print("BushOverlaySpawner ready")
	print("low_bush_scene: ", low_bush_scene)
	print("bush_textures count: ", bush_textures.size())
	spawn_bushes()


func spawn_bushes() -> void:
	if low_bush_scene == null:
		push_warning("BushOverlaySpawner: low_bush_scene is not assigned.")
		return

	if bush_textures.is_empty():
		push_warning("BushOverlaySpawner: bush_textures is empty.")
		return

	if clear_before_spawn:
		clear_existing_bushes()

	placed_positions.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	var start_x := int(spawn_area.position.x)
	var start_y := int(spawn_area.position.y)
	var end_x := int(spawn_area.position.x + spawn_area.size.x)
	var end_y := int(spawn_area.position.y + spawn_area.size.y)

	for y in range(start_y, end_y, candidate_spacing):
		for x in range(start_x, end_x, candidate_spacing):
			var base_pos := Vector2(x, y)

			if is_blocked_position(base_pos):
				continue

			var chance := get_spawn_chance_for_position(base_pos)

			if rng.randf() > chance:
				continue

			var bush_pos := find_valid_bush_position(base_pos, rng)

			if bush_pos == Vector2.INF:
				continue

			create_bush(bush_pos, rng)
			placed_positions.append(bush_pos)


func find_valid_bush_position(base_pos: Vector2, rng: RandomNumberGenerator) -> Vector2:
	for attempt in range(max_place_attempts):
		var offset := Vector2(
			rng.randi_range(-random_offset, random_offset),
			rng.randi_range(-random_offset, random_offset)
		)

		var candidate_pos := base_pos + offset

		if is_blocked_position(candidate_pos):
			continue

		if is_too_close_to_existing_bushes(candidate_pos):
			continue

		return candidate_pos

	return Vector2.INF


func create_bush(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var bush := low_bush_scene.instantiate()

	if not bush is LowBushOverlay:
		push_warning("BushOverlaySpawner: low_bush_scene root must be LowBushOverlay.")
		bush.queue_free()
		return

	var texture_index := rng.randi_range(0, bush_textures.size() - 1)
	var texture := bush_textures[texture_index]
	var flip_h := rng.randf() < 0.5

	add_child(bush)

	bush.add_to_group("farm_clearable_vegetation")
	bush.position = pos
	bush.z_index = 0
	bush.setup(texture, bush_material, flip_h)

	if bush_material != null:
		var sprite: Sprite2D = bush.get_node_or_null("Sprite2D")
		if sprite != null:
			sprite.set_instance_shader_parameter("wind_phase", rng.randf_range(0.0, TAU))
			sprite.set_instance_shader_parameter("wind_scale", rng.randf_range(0.45, 0.85))


func clear_existing_bushes() -> void:
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


func is_too_close_to_existing_bushes(pos: Vector2) -> bool:
	for existing_pos in placed_positions:
		if pos.distance_to(existing_pos) < min_bush_distance:
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


func spawn_test_bush() -> void:
	if low_bush_scene == null:
		push_warning("Test failed: low_bush_scene is null.")
		return

	if bush_textures.is_empty():
		push_warning("Test failed: bush_textures is empty.")
		return

	var bush := low_bush_scene.instantiate()

	print("Instantiated bush: ", bush)
	print("Bush script: ", bush.get_script())

	add_child(bush)

	bush.position = Vector2.ZERO

	if bush is LowBushOverlay:
		bush.setup(bush_textures[0], bush_material, false)
		print("Test bush created successfully.")
	else:
		push_warning("Test bush is not LowBushOverlay. Check scene root script.")
