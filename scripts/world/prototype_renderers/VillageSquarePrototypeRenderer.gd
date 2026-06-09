extends Node2D
class_name VillageSquareDebugRenderer

@export var renderEnabled: bool = true
@export var squareAreaId: String = "village_square_area"

@export var zIndexValue: int = -78
@export var baseAlpha: float = 0.72
@export var stoneAlpha: float = 0.85
@export var edgeAlpha: float = 0.75

@export var stoneCount: int = 140
@export var seedValue: int = 24680

var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("village_square_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("VillageSquareDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func refreshSquare() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null or worldGrid == null:
		return
	
	if not worldAreaManager.hasArea(squareAreaId):
		return
	
	drawVillageSquare()


func drawVillageSquare() -> void:
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(squareAreaId)
	
	drawSquareBase(worldRect)
	drawBrokenStonePaving(worldRect)
	drawSquareEdges(worldRect)
	drawCenterMark(worldRect)
	drawEmptyLotHints(worldRect)


func drawSquareBase(worldRect: Rect2) -> void:
	var baseColor: Color = Color(0.48, 0.44, 0.38, baseAlpha)
	var dirtColor: Color = Color(0.42, 0.32, 0.22, baseAlpha * 0.55)
	
	draw_rect(worldRect, dirtColor, true)
	
	var innerRect: Rect2 = worldRect.grow(-18.0)
	draw_rect(innerRect, baseColor, true)


func drawBrokenStonePaving(worldRect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	for i in range(stoneCount):
		var pos: Vector2 = Vector2(
			rng.randf_range(worldRect.position.x + 18.0, worldRect.position.x + worldRect.size.x - 18.0),
			rng.randf_range(worldRect.position.y + 18.0, worldRect.position.y + worldRect.size.y - 18.0)
		)
		
		var radiusX: float = rng.randf_range(5.0, 13.0)
		var radiusY: float = rng.randf_range(4.0, 10.0)
		
		var colorRoll: float = rng.randf()
		var stoneColor: Color
		
		if colorRoll < 0.35:
			stoneColor = Color(0.58, 0.55, 0.48, stoneAlpha)
		elif colorRoll < 0.7:
			stoneColor = Color(0.46, 0.44, 0.40, stoneAlpha)
		else:
			stoneColor = Color(0.66, 0.62, 0.52, stoneAlpha)
		
		drawOvalStone(pos, Vector2(radiusX, radiusY), stoneColor)
	
	# 조금 큰 깨진 판석 몇 개
	for i in range(18):
		var pos: Vector2 = Vector2(
			rng.randf_range(worldRect.position.x + 28.0, worldRect.position.x + worldRect.size.x - 28.0),
			rng.randf_range(worldRect.position.y + 28.0, worldRect.position.y + worldRect.size.y - 28.0)
		)
		
		drawCrackedSlab(pos, rng)


func drawOvalStone(pos: Vector2, radius: Vector2, color: Color) -> void:
	var shadowColor: Color = Color(0.20, 0.18, 0.16, color.a * 0.45)
	var highlightColor: Color = Color(0.82, 0.78, 0.66, color.a * 0.45)
	
	drawEllipse(pos + Vector2(1.5, 2.0), radius, shadowColor)
	drawEllipse(pos, radius, color)
	drawEllipse(pos + Vector2(-radius.x * 0.22, -radius.y * 0.25), radius * 0.35, highlightColor)


func drawCrackedSlab(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var w: float = rng.randf_range(24.0, 42.0)
	var h: float = rng.randf_range(16.0, 30.0)
	var skew: float = rng.randf_range(-6.0, 6.0)
	
	var points := PackedVector2Array([
		pos + Vector2(-w * 0.5 + skew, -h * 0.5),
		pos + Vector2(w * 0.5, -h * 0.45 + skew * 0.2),
		pos + Vector2(w * 0.45 - skew, h * 0.5),
		pos + Vector2(-w * 0.55, h * 0.45)
	])
	
	var slabColor: Color = Color(0.52, 0.50, 0.45, stoneAlpha)
	var crackColor: Color = Color(0.22, 0.20, 0.18, stoneAlpha * 0.75)
	
	draw_polygon(points, PackedColorArray([slabColor]))
	
	var crackStart: Vector2 = pos + Vector2(rng.randf_range(-w * 0.25, w * 0.1), -h * 0.35)
	var crackMid: Vector2 = pos + Vector2(rng.randf_range(-w * 0.05, w * 0.2), rng.randf_range(-h * 0.05, h * 0.1))
	var crackEnd: Vector2 = pos + Vector2(rng.randf_range(-w * 0.2, w * 0.25), h * 0.35)
	
	draw_line(crackStart, crackMid, crackColor, 1.0)
	draw_line(crackMid, crackEnd, crackColor, 1.0)


func drawSquareEdges(worldRect: Rect2) -> void:
	var edgeColor: Color = Color(0.30, 0.26, 0.20, edgeAlpha)
	var lightEdge: Color = Color(0.66, 0.60, 0.48, edgeAlpha * 0.7)
	
	draw_rect(worldRect, edgeColor, false, 5.0)
	draw_rect(worldRect.grow(-7.0), lightEdge, false, 2.0)


func drawCenterMark(worldRect: Rect2) -> void:
	var center: Vector2 = worldRect.position + worldRect.size * 0.5
	
	var ringColor: Color = Color(0.62, 0.57, 0.46, 0.55)
	var fadedColor: Color = Color(0.78, 0.70, 0.52, 0.28)
	
	draw_circle(center, 54.0, fadedColor)
	draw_arc(center, 54.0, 0.0, TAU, 48, ringColor, 3.0)
	draw_arc(center, 30.0, 0.0, TAU, 36, ringColor, 2.0)
	
	draw_line(center + Vector2(-42, 0), center + Vector2(42, 0), ringColor, 2.0)
	draw_line(center + Vector2(0, -42), center + Vector2(0, 42), ringColor, 2.0)


func drawEmptyLotHints(worldRect: Rect2) -> void:
	# 미래 상점/가판대가 들어올 수 있는 자리 느낌만 약하게 표시.
	var lotColor: Color = Color(0.95, 0.82, 0.52, 0.30)
	var postColor: Color = Color(0.36, 0.25, 0.16, 0.65)
	
	var lotA := Rect2(
		worldRect.position + Vector2(24, 24),
		Vector2(170, 96)
	)
	
	var lotB := Rect2(
		worldRect.position + Vector2(worldRect.size.x - 210, 30),
		Vector2(170, 96)
	)
	
	drawLotHint(lotA, lotColor, postColor)
	drawLotHint(lotB, lotColor, postColor)


func drawLotHint(rect: Rect2, lotColor: Color, postColor: Color) -> void:
	draw_rect(rect, lotColor, false, 2.0)
	
	var posts: Array[Vector2] = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(0, rect.size.y),
		rect.position + rect.size
	]
	
	for p in posts:
		draw_circle(p, 5.0, postColor)


func drawEllipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var steps: int = 18
	
	for i in range(steps):
		var angle: float = TAU * float(i) / float(steps)
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	
	draw_polygon(points, PackedColorArray([color]))
