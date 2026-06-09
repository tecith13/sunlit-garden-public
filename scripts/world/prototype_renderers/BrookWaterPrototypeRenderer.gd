extends Node2D
class_name BrookWaterDebugRenderer

@export var renderEnabled: bool = true
@export var targetAreaId: String = "brook_area"

# 1이면 모든 water cell을 그림.
# 렉이 있으면 2로 올릴 수 있지만, 물길은 얇으므로 기본 1 추천.
@export var renderStepCells: int = 1

@export var zIndexValue: int = -70
@export var waterAlpha: float = 0.9
@export var edgeAlpha: float = 0.45

# 실제 cell보다 조금 크게 그려서 물길이 끊겨 보이지 않게 함.
@export var cellPadding: float = 1.5

var terrainManager: TerrainManager = null
var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("brook_water_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("BrookWaterDebugRenderer ready.")
	call_deferred("refreshBrook")


func refreshReferences() -> void:
	if terrainManager == null:
		terrainManager = get_tree().get_first_node_in_group("terrain_manager")
	
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func refreshBrook() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if terrainManager == null or worldAreaManager == null or worldGrid == null:
		return
	
	if not worldAreaManager.hasArea(targetAreaId):
		return
	
	drawBrookWater()


func drawBrookWater() -> void:
	var areaRect: Rect2i = worldAreaManager.getAreaRect(targetAreaId)
	var step: int = max(1, renderStepCells)
	
	# 1차: 물가 edge를 먼저 그림
	for y in range(areaRect.position.y, areaRect.position.y + areaRect.size.y, step):
		for x in range(areaRect.position.x, areaRect.position.x + areaRect.size.x, step):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			var terrainId: String = str(data.get("terrainId", ""))
			var overlayId: String = str(data.get("overlayId", ""))
			
			if terrainId == "wet_grass" or overlayId == "water_edge":
				drawWaterEdgeCell(cell)
	
	# 2차: 물을 위에 그림
	for y in range(areaRect.position.y, areaRect.position.y + areaRect.size.y, step):
		for x in range(areaRect.position.x, areaRect.position.x + areaRect.size.x, step):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			if bool(data.get("water", false)):
				drawWaterCell(cell)


func drawWaterCell(cell: Vector2i) -> void:
	var worldPos: Vector2 = worldGrid.cell_to_world(cell)
	var size: float = float(WorldGrid.CELL_SIZE * renderStepCells)
	
	var rect: Rect2 = Rect2(
		worldPos - Vector2(cellPadding, cellPadding),
		Vector2(size + cellPadding * 2.0, size + cellPadding * 2.0)
	)
	
	var baseColor: Color = Color(0.10, 0.42, 0.95, waterAlpha)
	var deepColor: Color = Color(0.04, 0.22, 0.70, waterAlpha * 0.5)
	var shineColor: Color = Color(0.55, 0.82, 1.0, waterAlpha * 0.35)
	
	draw_rect(rect, baseColor, true)
	
	# 약한 깊이감
	draw_rect(
		Rect2(rect.position + Vector2(0, rect.size.y * 0.55), Vector2(rect.size.x, rect.size.y * 0.45)),
		deepColor,
		true
	)
	
	# 작은 하이라이트. 모든 셀에 너무 강하지 않게 패턴화.
	if (cell.x + cell.y) % 7 == 0:
		draw_line(
			rect.position + Vector2(3, 4),
			rect.position + Vector2(rect.size.x - 4, 4),
			shineColor,
			1.0
		)


func drawWaterEdgeCell(cell: Vector2i) -> void:
	var worldPos: Vector2 = worldGrid.cell_to_world(cell)
	var size: float = float(WorldGrid.CELL_SIZE * renderStepCells)
	
	var rect: Rect2 = Rect2(worldPos, Vector2(size, size))
	
	var edgeColor: Color = Color(0.20, 0.55, 0.42, edgeAlpha)
	var mudColor: Color = Color(0.34, 0.42, 0.26, edgeAlpha * 0.6)
	
	draw_rect(rect, edgeColor, true)
	
	if (cell.x * 3 + cell.y) % 5 == 0:
		draw_circle(
			worldPos + Vector2(size * 0.5, size * 0.55),
			2.5,
			mudColor
		)
