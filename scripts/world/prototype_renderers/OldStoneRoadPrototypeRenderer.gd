extends Node2D
class_name OldStoneRoadDebugRenderer

@export var renderEnabled: bool = true
@export var roadAreaId: String = "old_stone_road_area"

@export var roadWidthCells: int = 10
@export var stoneCount: int = 80
@export var seedValue: int = 12345

@export var zIndexValue: int = -80
@export var roadAlpha: float = 0.75
@export var stoneAlpha: float = 0.95

var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("old_stone_road_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("OldStoneRoadDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func refreshRoad() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null or worldGrid == null:
		return
	
	if not worldAreaManager.hasArea(roadAreaId):
		return
	
	drawOldStoneRoad()


func drawOldStoneRoad() -> void:
	var areaRect: Rect2i = worldAreaManager.getAreaRect(roadAreaId)
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(roadAreaId)
	
	var cellSize: int = WorldGrid.CELL_SIZE
	var roadWidth: float = float(roadWidthCells * cellSize)
	
	var topCenter: Vector2 = Vector2(
		worldRect.position.x + worldRect.size.x * 0.5,
		worldRect.position.y
	)
	
	var bottomCenter: Vector2 = Vector2(
		worldRect.position.x + worldRect.size.x * 0.5,
		worldRect.position.y + worldRect.size.y
	)
	
	# 살짝 구불구불한 중심선.
	var leftPoints: PackedVector2Array = PackedVector2Array()
	var rightPoints: PackedVector2Array = PackedVector2Array()
	
	var segments: int = 18
	
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var y: float = lerp(topCenter.y, bottomCenter.y, t)
		
		var wave: float = sin(t * PI * 2.1 + 0.4) * 28.0
		var wave2: float = sin(t * PI * 5.0) * 10.0
		var centerX: float = topCenter.x + wave + wave2
		
		var widthVariation: float = sin(t * PI * 3.0 + 1.2) * 10.0
		var halfWidth: float = roadWidth * 0.5 + widthVariation
		
		leftPoints.append(Vector2(centerX - halfWidth, y))
		rightPoints.append(Vector2(centerX + halfWidth, y))
	
	var roadPolygon: PackedVector2Array = PackedVector2Array()
	
	for p in leftPoints:
		roadPolygon.append(p)
	
	for i in range(rightPoints.size() - 1, -1, -1):
		roadPolygon.append(rightPoints[i])
	
	draw_polygon(
		roadPolygon,
		PackedColorArray([Color(0.52, 0.39, 0.24, roadAlpha)])
	)
	
	drawRoadEdgeStones(leftPoints, rightPoints)
	drawCenterStones(worldRect, roadWidth)


func drawRoadEdgeStones(leftPoints: PackedVector2Array, rightPoints: PackedVector2Array) -> void:
	for i in range(leftPoints.size()):
		if i % 2 == 0:
			drawSmallStone(leftPoints[i] + Vector2(randOffset(i), 0), 5.0)
		
		if i % 3 == 0:
			drawSmallStone(rightPoints[i] + Vector2(randOffset(i + 11), 0), 5.0)


func drawCenterStones(worldRect: Rect2, roadWidth: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	for i in range(stoneCount):
		var t: float = rng.randf()
		var y: float = lerp(worldRect.position.y + 12.0, worldRect.position.y + worldRect.size.y - 12.0, t)
		
		var wave: float = sin(t * PI * 2.1 + 0.4) * 28.0
		var wave2: float = sin(t * PI * 5.0) * 10.0
		var centerX: float = worldRect.position.x + worldRect.size.x * 0.5 + wave + wave2
		
		var x: float = centerX + rng.randf_range(-roadWidth * 0.35, roadWidth * 0.35)
		var radius: float = rng.randf_range(3.0, 8.0)
		
		drawSmallStone(Vector2(x, y), radius)


func drawSmallStone(pos: Vector2, radius: float) -> void:
	var baseColor := Color(0.63, 0.58, 0.48, stoneAlpha)
	var shadowColor := Color(0.32, 0.27, 0.22, stoneAlpha * 0.55)
	var highlightColor := Color(0.78, 0.72, 0.60, stoneAlpha * 0.75)
	
	draw_circle(pos + Vector2(1.5, 2.0), radius, shadowColor)
	draw_circle(pos, radius, baseColor)
	draw_circle(pos + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.35, highlightColor)


func randOffset(value: int) -> float:
	var raw: int = int(abs(hash(str(value)))) % 100
	return float(raw - 50) * 0.18
