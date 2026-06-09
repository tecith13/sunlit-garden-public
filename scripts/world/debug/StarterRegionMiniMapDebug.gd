extends Control
class_name StarterRegionMiniMapDebug

@export var debugVisible: bool = true
@export var mapSize: Vector2 = Vector2(360, 360)
@export var mapPosition: Vector2 = Vector2(24, 24)
@export var drawEveryNCells: int = 8
@export var drawAreaBorders: bool = true
@export var drawAreaLabels: bool = true

@export var drawWaterOverlay: bool = true
@export var waterOverlayStep: int = 1
@export var drawBlockedOverlay: bool = true

var terrainManager: TerrainManager = null
var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("starter_region_minimap_debug")
	refreshReferences()
	position = mapPosition
	size = mapSize
	print("StarterRegionMiniMapDebug ready.")
	queue_redraw()


func refreshReferences() -> void:
	if terrainManager == null:
		terrainManager = get_tree().get_first_node_in_group("terrain_manager")
	
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshDebugDraw() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not debugVisible:
		return
	
	refreshReferences()
	
	if terrainManager == null or worldAreaManager == null:
		return
	
	var starterRect: Rect2i = worldAreaManager.getAreaRect("starter_region")
	
	draw_rect(Rect2(Vector2.ZERO, mapSize), Color(0.04, 0.035, 0.025, 0.72), true)
	draw_rect(Rect2(Vector2.ZERO, mapSize), Color(1.0, 0.9, 0.65, 0.75), false, 2.0)
	
	drawTerrainOverview(starterRect)

	if drawWaterOverlay:
		drawWaterCellsOverlay(starterRect)

	if drawBlockedOverlay:
		drawBlockedCellsOverlay(starterRect)

	if drawAreaBorders:
		drawAreasOverview(starterRect)


func cellToMiniMapPosition(cell: Vector2i, starterRect: Rect2i) -> Vector2:
	var localX: float = float(cell.x - starterRect.position.x) / float(starterRect.size.x)
	var localY: float = float(cell.y - starterRect.position.y) / float(starterRect.size.y)
	
	return Vector2(
		localX * mapSize.x,
		localY * mapSize.y
	)


func cellSizeToMiniMapSize(cellSize: Vector2i, starterRect: Rect2i) -> Vector2:
	return Vector2(
		float(cellSize.x) / float(starterRect.size.x) * mapSize.x,
		float(cellSize.y) / float(starterRect.size.y) * mapSize.y
	)


func drawTerrainOverview(starterRect: Rect2i) -> void:
	for y in range(starterRect.position.y, starterRect.position.y + starterRect.size.y, drawEveryNCells):
		for x in range(starterRect.position.x, starterRect.position.x + starterRect.size.x, drawEveryNCells):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			var miniPos: Vector2 = cellToMiniMapPosition(cell, starterRect)
			var miniSize: Vector2 = cellSizeToMiniMapSize(
				Vector2i(drawEveryNCells, drawEveryNCells),
				starterRect
			)
			
			draw_rect(
				Rect2(miniPos, miniSize),
				getTerrainDebugColor(data),
				true
			)


func drawAreasOverview(starterRect: Rect2i) -> void:
	for areaId in worldAreaManager.getAreaIds():
		if areaId == "starter_region":
			continue
		
		var areaRect: Rect2i = worldAreaManager.getAreaRect(areaId)
		var miniPos: Vector2 = cellToMiniMapPosition(areaRect.position, starterRect)
		var miniSize: Vector2 = cellSizeToMiniMapSize(areaRect.size, starterRect)
		var color: Color = getAreaBorderColor(areaId)
		
		draw_rect(Rect2(miniPos, miniSize), color, false, 1.5)
		
		if drawAreaLabels:
			drawAreaLabel(areaId, miniPos + Vector2(3, 10), color)


func getTerrainDebugColor(data: Dictionary) -> Color:
	var terrainId: String = str(data.get("terrainId", "grass"))
	var height: int = int(data.get("height", 0))
	var water: bool = bool(data.get("water", false))
	var blocked: bool = bool(data.get("blocked", false))
	
	if water:
		return Color(0.1, 0.45, 1.0, 0.75)
	
	if blocked:
		return Color(0.95, 0.15, 0.12, 0.72)
	
	match terrainId:
		"forest_floor":
			return Color(0.05, 0.45, 0.16, 0.65)
		"forest_path_blocked":
			return Color(0.25, 0.25, 0.12, 0.75)
		"dry_grass":
			return Color(0.7, 0.55, 0.22, 0.62)
		"stone_ground":
			return Color(0.6, 0.55, 0.72, 0.68)
		"rocky_ground":
			return Color(0.45, 0.5, 0.6, 0.70)
		"wild_grass":
			return Color(0.25, 0.75, 0.35, 0.55)
		"dirt":
			return Color(0.62, 0.36, 0.18, 0.62)
		_:
			if height > 0:
				return Color(0.65, 0.52, 1.0, 0.56)
			elif height < 0:
				return Color(0.2, 0.45, 0.9, 0.56)
			else:
				return Color(0.22, 0.75, 0.28, 0.42)


func getAreaBorderColor(areaId: String) -> Color:
	match areaId:
		"player_home_area":
			return Color(0.4, 1.0, 0.45, 0.95)
		"house_plot":
			return Color(1.0, 0.9, 0.25, 0.95)
		"back_forest_area":
			return Color(0.15, 0.9, 0.25, 0.95)
		"blocked_old_path_area":
			return Color(1.0, 0.2, 0.1, 0.95)
		"brook_area":
			return Color(0.2, 0.65, 1.0, 0.95)
		"village_square_area":
			return Color(0.85, 0.55, 1.0, 0.95)
		"old_stone_road_area":
			return Color(1.0, 1.0, 0.25, 0.95)
		_:
			return Color(1.0, 1.0, 1.0, 0.75)


func drawAreaLabel(areaId: String, labelPosition: Vector2, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	
	draw_string(
		font,
		labelPosition,
		areaId,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		8,
		color
	)


func drawWaterCellsOverlay(starterRect: Rect2i) -> void:
	for y in range(starterRect.position.y, starterRect.position.y + starterRect.size.y, waterOverlayStep):
		for x in range(starterRect.position.x, starterRect.position.x + starterRect.size.x, waterOverlayStep):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			if not bool(data.get("water", false)):
				continue
			
			var miniPos: Vector2 = cellToMiniMapPosition(cell, starterRect)
			var miniSize: Vector2 = cellSizeToMiniMapSize(
				Vector2i(waterOverlayStep, waterOverlayStep),
				starterRect
			)
			
			draw_rect(
				Rect2(miniPos, miniSize),
				Color(0.0, 0.25, 1.0, 1.0),
				true
			)


func drawBlockedCellsOverlay(starterRect: Rect2i) -> void:
	for y in range(starterRect.position.y, starterRect.position.y + starterRect.size.y, waterOverlayStep):
		for x in range(starterRect.position.x, starterRect.position.x + starterRect.size.x, waterOverlayStep):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			if not bool(data.get("blocked", false)):
				continue
			
			var miniPos: Vector2 = cellToMiniMapPosition(cell, starterRect)
			var miniSize: Vector2 = cellSizeToMiniMapSize(
				Vector2i(waterOverlayStep + 1, waterOverlayStep + 1),
				starterRect
			)
			
			draw_rect(
				Rect2(miniPos, miniSize),
				Color(1.0, 0.1, 0.1, 0.55),
				true
			)
