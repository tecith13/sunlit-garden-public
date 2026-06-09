extends Node
class_name WorldGrid

const CELL_SIZE: int = 16

# 현재 화면/캐릭터 스케일 기준 후보값.
# 나중에 바꿔도 좌표 변환 함수만 유지하면 됨.
const CHUNK_SIZE_CELLS: int = 128
const CHUNK_SIZE_PIXELS: int = CELL_SIZE * CHUNK_SIZE_CELLS


func _ready() -> void:
	add_to_group("world_grid")
	print("WorldGrid ready. Cell:", CELL_SIZE, " ChunkPixels:", CHUNK_SIZE_PIXELS)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / float(CELL_SIZE)),
		floori(world_position.y / float(CELL_SIZE))
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE,
		cell.y * CELL_SIZE
	)


func cell_to_world_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * CELL_SIZE + CELL_SIZE * 0.5,
		cell.y * CELL_SIZE + CELL_SIZE * 0.5
	)


func world_to_chunk(world_position: Vector2) -> Vector2i:
	return cell_to_chunk(world_to_cell(world_position))


func cell_to_chunk(cell: Vector2i) -> Vector2i:
	return Vector2i(
		floori(cell.x / float(CHUNK_SIZE_CELLS)),
		floori(cell.y / float(CHUNK_SIZE_CELLS))
	)


func chunk_to_world_origin(chunk: Vector2i) -> Vector2:
	return Vector2(
		chunk.x * CHUNK_SIZE_PIXELS,
		chunk.y * CHUNK_SIZE_PIXELS
	)


func chunk_to_cell_origin(chunk: Vector2i) -> Vector2i:
	return Vector2i(
		chunk.x * CHUNK_SIZE_CELLS,
		chunk.y * CHUNK_SIZE_CELLS
	)


func get_chunk_rect_cells(chunk: Vector2i) -> Rect2i:
	return Rect2i(
		chunk_to_cell_origin(chunk),
		Vector2i(CHUNK_SIZE_CELLS, CHUNK_SIZE_CELLS)
	)


func get_chunk_rect_world(chunk: Vector2i) -> Rect2:
	return Rect2(
		chunk_to_world_origin(chunk),
		Vector2(CHUNK_SIZE_PIXELS, CHUNK_SIZE_PIXELS)
	)


func get_cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func get_chunk_key(chunk: Vector2i) -> String:
	return "%d,%d" % [chunk.x, chunk.y]


func parse_vector2i_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() != 2:
		push_warning("Invalid Vector2i key: " + key)
		return Vector2i.ZERO
	
	return Vector2i(int(parts[0]), int(parts[1]))
