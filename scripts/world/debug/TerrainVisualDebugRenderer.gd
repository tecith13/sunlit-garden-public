extends Node2D
class_name TerrainVisualDebugRenderer

@export var renderEnabled: bool = true

# 너무 넓은 영역을 1셀 단위로 다 그리면 무겁다.
# 실제 맵 제작 전 디버그용이므로 기본 4셀 단위로 렌더링.
@export var renderStepCells: int = 4

# 1이면 실제 cellSize 그대로.
# renderStepCells가 4면 한 사각형이 4x4 cell 영역을 대표함.
@export var alpha: float = 0.55

@export var drawBlockedBorder: bool = true
@export var drawWaterStrong: bool = true
@export var drawHeightTint: bool = true

var terrainManager: TerrainManager = null
var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("terrain_visual_debug_renderer")
	refreshReferences()
	print("TerrainVisualDebugRenderer ready.")
	call_deferred("refreshRender")


func refreshReferences() -> void:
	if terrainManager == null:
		terrainManager = get_tree().get_first_node_in_group("terrain_manager")
	
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func refreshRender() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if terrainManager == null or worldAreaManager == null or worldGrid == null:
		return
	
	drawStarterRegionTerrain()


func drawStarterRegionTerrain() -> void:
	var starterRect: Rect2i = worldAreaManager.getAreaRect("starter_region")
	
	for y in range(starterRect.position.y, starterRect.position.y + starterRect.size.y, renderStepCells):
		for x in range(starterRect.position.x, starterRect.position.x + starterRect.size.x, renderStepCells):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			drawTerrainBlock(cell, data)


func drawTerrainBlock(cell: Vector2i, data: Dictionary) -> void:
	var worldPos: Vector2 = worldGrid.cell_to_world(cell)
	var blockSize: float = float(WorldGrid.CELL_SIZE * renderStepCells)
	var rect: Rect2 = Rect2(worldPos, Vector2(blockSize, blockSize))
	
	var fillColor: Color = getTerrainColor(data)
	fillColor.a = alpha
	
	draw_rect(rect, fillColor, true)
	
	if drawHeightTint:
		drawHeightOverlay(rect, data)
	
	if drawBlockedBorder and bool(data.get("blocked", false)):
		draw_rect(rect, Color(1.0, 0.05, 0.05, 0.8), false, 2.0)


func drawHeightOverlay(rect: Rect2, data: Dictionary) -> void:
	var height: int = int(data.get("height", 0))
	
	if height > 0:
		draw_rect(rect, Color(0.75, 0.65, 1.0, 0.16), true)
	elif height < 0:
		draw_rect(rect, Color(0.1, 0.2, 0.7, 0.20), true)


func getTerrainColor(data: Dictionary) -> Color:
	var terrainId: String = str(data.get("terrainId", "grass"))
	var water: bool = bool(data.get("water", false))
	var blocked: bool = bool(data.get("blocked", false))
	
	if water:
		if drawWaterStrong:
			return Color(0.0, 0.28, 1.0, 1.0)
		return Color(0.1, 0.45, 1.0, 1.0)
	
	if blocked:
		return Color(0.75, 0.12, 0.08, 1.0)
	
	match terrainId:
		"grass":
			return Color(0.25, 0.70, 0.25, 1.0)
		"dry_grass":
			return Color(0.72, 0.58, 0.24, 1.0)
		"forest_floor":
			return Color(0.08, 0.42, 0.16, 1.0)
		"forest_path_blocked":
			return Color(0.25, 0.28, 0.12, 1.0)
		"riverbank":
			return Color(0.34, 0.62, 0.30, 1.0)
		"wet_grass":
			return Color(0.18, 0.55, 0.36, 1.0)
		"stone_ground":
			return Color(0.55, 0.52, 0.62, 1.0)
		"rocky_ground":
			return Color(0.42, 0.45, 0.50, 1.0)
		"wild_grass":
			return Color(0.28, 0.68, 0.32, 1.0)
		"dirt":
			return Color(0.56, 0.34, 0.18, 1.0)
		_:
			return Color(0.35, 0.65, 0.30, 1.0)
