extends Node2D
class_name BackForestBlockedPathDebugRenderer

@export var renderEnabled: bool = true

@export var backForestAreaId: String = "back_forest_area"
@export var blockedPathAreaId: String = "blocked_old_path_area"
@export var archiveRouteAreaId: String = "archive_route_area"

@export var zIndexValue: int = -57
@export var forestAlpha: float = 0.82
@export var pathAlpha: float = 0.86
@export var blockerAlpha: float = 0.95

@export var treeStumpCount: int = 22
@export var stoneCount: int = 28
@export var seedValue: int = 97531

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("back_forest_blocked_path_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("BackForestBlockedPathDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshForestPath() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	drawBackForest()
	drawBlockedPath()
	drawArchiveRouteHint()


func drawBackForest() -> void:
	if not worldAreaManager.hasArea(backForestAreaId):
		return
	
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(backForestAreaId)
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	# 숲 바닥 위에 어두운 숲 그늘 패치
	draw_rect(worldRect.grow(-10.0), Color(0.06, 0.24, 0.10, forestAlpha * 0.28), true)
	
	# 숲 가장자리 느낌의 덤불/나무 그림자
	for i in range(treeStumpCount):
		var p: Vector2 = Vector2(
			rng.randf_range(worldRect.position.x + 16.0, worldRect.position.x + worldRect.size.x - 16.0),
			rng.randf_range(worldRect.position.y + 12.0, worldRect.position.y + worldRect.size.y - 12.0)
		)
		
		if i % 3 == 0:
			drawTreeStump(p, rng)
		else:
			drawBushClump(p, rng)
	
	# 숲 아래쪽 경계: 집 뒤로 이어지는 느낌
	var edgeY: float = worldRect.position.y + worldRect.size.y - 8.0
	draw_line(
		Vector2(worldRect.position.x + 12.0, edgeY),
		Vector2(worldRect.position.x + worldRect.size.x - 12.0, edgeY),
		Color(0.18, 0.38, 0.14, forestAlpha * 0.6),
		3.0
	)


func drawBlockedPath() -> void:
	if not worldAreaManager.hasArea(blockedPathAreaId):
		return
	
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(blockedPathAreaId)
	var center: Vector2 = worldRect.position + worldRect.size * 0.5
	
	drawOldPathGround(worldRect)
	drawFallenLogs(center, worldRect)
	drawBlockingVines(worldRect)
	drawSmallStones(worldRect)


func drawOldPathGround(worldRect: Rect2) -> void:
	var dirt: Color = Color(0.33, 0.25, 0.15, pathAlpha * 0.65)
	var moss: Color = Color(0.18, 0.34, 0.13, pathAlpha * 0.45)
	
	var pathRect: Rect2 = worldRect.grow(-8.0)
	draw_rect(pathRect, dirt, true)
	
	for i in range(16):
		var p: Vector2 = pseudoRandomPointInRect(pathRect, i + 200)
		draw_circle(p, randRange(i + 5, 4.0, 11.0), moss)


func drawFallenLogs(center: Vector2, worldRect: Rect2) -> void:
	var logColor: Color = Color(0.38, 0.22, 0.12, blockerAlpha)
	var logDark: Color = Color(0.17, 0.09, 0.05, blockerAlpha)
	var cutColor: Color = Color(0.70, 0.52, 0.30, blockerAlpha * 0.9)
	
	var logAStart: Vector2 = center + Vector2(-38, -16)
	var logAEnd: Vector2 = center + Vector2(44, 18)
	var logBStart: Vector2 = center + Vector2(-44, 22)
	var logBEnd: Vector2 = center + Vector2(38, -20)
	
	drawLog(logAStart, logAEnd, logColor, logDark, cutColor)
	drawLog(logBStart, logBEnd, logColor, logDark, cutColor)
	
	# 작은 가지
	draw_line(center + Vector2(-8, -4), center + Vector2(-34, -42), logDark, 4.0)
	draw_line(center + Vector2(12, 8), center + Vector2(42, 42), logDark, 3.0)


func drawLog(start: Vector2, end: Vector2, logColor: Color, logDark: Color, cutColor: Color) -> void:
	draw_line(start + Vector2(2, 3), end + Vector2(2, 3), logDark, 15.0)
	draw_line(start, end, logColor, 13.0)
	draw_circle(start, 7.5, cutColor)
	draw_circle(end, 7.5, cutColor)
	draw_circle(start, 7.5, logDark)
	draw_circle(end, 7.5, logDark)
	draw_circle(start, 5.2, cutColor)
	draw_circle(end, 5.2, cutColor)


func drawBlockingVines(worldRect: Rect2) -> void:
	var vineColor: Color = Color(0.10, 0.36, 0.12, blockerAlpha)
	var leafColor: Color = Color(0.22, 0.58, 0.18, blockerAlpha)
	
	for i in range(7):
		var startX: float = lerp(worldRect.position.x + 8.0, worldRect.position.x + worldRect.size.x - 8.0, float(i) / 6.0)
		var start: Vector2 = Vector2(startX, worldRect.position.y + randRange(i, 4.0, 18.0))
		var end: Vector2 = Vector2(startX + randRange(i + 40, -18.0, 18.0), worldRect.position.y + worldRect.size.y - randRange(i + 80, 4.0, 18.0))
		
		draw_line(start, end, vineColor, 2.0)
		
		for j in range(4):
			var t: float = float(j + 1) / 5.0
			var p: Vector2 = start.lerp(end, t)
			draw_circle(p + Vector2(randRange(i * 10 + j, -3.0, 3.0), randRange(i * 20 + j, -3.0, 3.0)), 3.0, leafColor)


func drawSmallStones(worldRect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue + 42
	
	for i in range(stoneCount):
		var p: Vector2 = Vector2(
			rng.randf_range(worldRect.position.x + 4.0, worldRect.position.x + worldRect.size.x - 4.0),
			rng.randf_range(worldRect.position.y + 4.0, worldRect.position.y + worldRect.size.y - 4.0)
		)
		
		var radius: float = rng.randf_range(2.5, 6.5)
		draw_circle(p + Vector2(1.0, 1.5), radius, Color(0.12, 0.10, 0.08, 0.35))
		draw_circle(p, radius, Color(0.42, 0.40, 0.35, 0.75))


func drawArchiveRouteHint() -> void:
	if not worldAreaManager.hasArea(archiveRouteAreaId):
		return
	
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(archiveRouteAreaId)
	
	# 아직 갈 수 없는 숲속 깊은 길의 희미한 흔적
	var mistColor: Color = Color(0.58, 0.78, 0.56, 0.18)
	var markColor: Color = Color(0.74, 0.68, 0.44, 0.35)
	
	draw_rect(worldRect.grow(-12.0), mistColor, true)
	
	var center: Vector2 = worldRect.position + worldRect.size * 0.5
	draw_arc(center, 28.0, 0.0, TAU, 28, markColor, 2.0)
	draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), markColor, 1.5)


func drawTreeStump(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var stumpColor: Color = Color(0.37, 0.23, 0.13, forestAlpha)
	var ringColor: Color = Color(0.68, 0.50, 0.28, forestAlpha * 0.85)
	var dark: Color = Color(0.13, 0.08, 0.04, forestAlpha * 0.7)
	
	var radius: float = rng.randf_range(8.0, 14.0)
	draw_circle(pos + Vector2(1.5, 2.5), radius, dark)
	draw_circle(pos, radius, stumpColor)
	draw_arc(pos, radius * 0.55, 0.0, TAU, 18, ringColor, 1.5)


func drawBushClump(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var dark: Color = Color(0.06, 0.25, 0.08, forestAlpha * 0.85)
	var mid: Color = Color(0.12, 0.42, 0.13, forestAlpha * 0.75)
	var light: Color = Color(0.24, 0.56, 0.18, forestAlpha * 0.55)
	
	var r: float = rng.randf_range(8.0, 18.0)
	draw_circle(pos + Vector2(-4, 2), r * 0.75, dark)
	draw_circle(pos + Vector2(5, 1), r * 0.70, mid)
	draw_circle(pos + Vector2(0, -5), r * 0.55, light)


func pseudoRandomPointInRect(rect: Rect2, index: int) -> Vector2:
	var x: float = rect.position.x + rand01(index * 17 + 5) * rect.size.x
	var y: float = rect.position.y + rand01(index * 31 + 11) * rect.size.y
	return Vector2(x, y)


func rand01(value: int) -> float:
	var raw: int = int(abs(hash(str(value)))) % 10000
	return float(raw) / 10000.0


func randRange(value: int, minValue: float, maxValue: float) -> float:
	return lerp(minValue, maxValue, rand01(value))
