extends Node2D
class_name ShippingTradeAreaDebugRenderer

@export var renderEnabled: bool = true
@export var tradeAreaId: String = "shipping_trade_area"

@export var zIndexValue: int = -59
@export var baseAlpha: float = 0.76
@export var woodAlpha: float = 0.95
@export var ropeAlpha: float = 0.85

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("shipping_trade_area_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("ShippingTradeAreaDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshTradeArea() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	if not worldAreaManager.hasArea(tradeAreaId):
		return
	
	drawShippingTradeArea()


func drawShippingTradeArea() -> void:
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(tradeAreaId)
	var center: Vector2 = worldRect.position + worldRect.size * 0.5
	
	drawGroundPatch(worldRect)
	drawLoadingPlatform(center)
	drawCratesAndSacks(center)
	drawTradeBoard(center)
	drawRouteMarkers(worldRect)


func drawGroundPatch(worldRect: Rect2) -> void:
	var dirtColor: Color = Color(0.42, 0.30, 0.18, baseAlpha * 0.58)
	var packedEarth: Color = Color(0.55, 0.42, 0.25, baseAlpha * 0.38)
	var edgeColor: Color = Color(0.82, 0.66, 0.36, baseAlpha * 0.30)
	
	var patch: Rect2 = worldRect.grow(10.0)
	draw_rect(patch, dirtColor, true)
	draw_rect(patch, edgeColor, false, 1.5)
	
	for i in range(16):
		var p: Vector2 = pseudoRandomPointInRect(patch, i)
		draw_circle(p, randRange(i + 9, 2.0, 4.0), packedEarth)


func drawLoadingPlatform(center: Vector2) -> void:
	var wood: Color = Color(0.46, 0.28, 0.15, woodAlpha)
	var darkWood: Color = Color(0.20, 0.12, 0.07, woodAlpha)
	var lightWood: Color = Color(0.66, 0.45, 0.24, woodAlpha * 0.75)
	
	var platform := Rect2(center + Vector2(-92, -22), Vector2(184, 48))
	
	draw_rect(platform, wood, true)
	draw_rect(platform, darkWood, false, 2.0)
	
	# 나무 판자 줄
	for i in range(1, 5):
		var y: float = platform.position.y + float(i) * platform.size.y / 5.0
		draw_line(
			Vector2(platform.position.x, y),
			Vector2(platform.position.x + platform.size.x, y),
			darkWood,
			1.0
		)
	
	# 하이라이트
	draw_line(
		platform.position + Vector2(8, 7),
		platform.position + Vector2(platform.size.x - 8, 7),
		lightWood,
		1.0
	)
	
	# 짧은 말뚝
	var postPositions: Array[Vector2] = [
		platform.position + Vector2(10, -10),
		platform.position + Vector2(platform.size.x - 18, -10),
		platform.position + Vector2(10, platform.size.y + 2),
		platform.position + Vector2(platform.size.x - 18, platform.size.y + 2)
	]
	
	for p in postPositions:
		draw_rect(Rect2(p, Vector2(8, 20)), darkWood, true)


func drawCratesAndSacks(center: Vector2) -> void:
	var crateColor: Color = Color(0.54, 0.34, 0.17, 0.95)
	var crateDark: Color = Color(0.22, 0.13, 0.08, 0.9)
	var sackColor: Color = Color(0.72, 0.62, 0.42, 0.9)
	var sackDark: Color = Color(0.38, 0.30, 0.18, 0.65)
	
	var crates: Array[Rect2] = [
		Rect2(center + Vector2(-80, -12), Vector2(34, 28)),
		Rect2(center + Vector2(-42, -8), Vector2(30, 24)),
		Rect2(center + Vector2(44, -10), Vector2(36, 28)),
		Rect2(center + Vector2(82, 8), Vector2(30, 24))
	]
	
	for r in crates:
		draw_rect(r, crateColor, true)
		draw_rect(r, crateDark, false, 1.5)
		draw_line(r.position, r.position + r.size, crateDark, 1.0)
		draw_line(r.position + Vector2(r.size.x, 0), r.position + Vector2(0, r.size.y), crateDark, 1.0)
	
	var sacks: Array[Vector2] = [
		center + Vector2(-8, 18),
		center + Vector2(18, 20),
		center + Vector2(10, -20)
	]
	
	for i in range(sacks.size()):
		var p: Vector2 = sacks[i]
		draw_circle(p + Vector2(0, 7), 14.0, sackDark)
		draw_circle(p, 13.0, sackColor)
		draw_line(p + Vector2(-8, -8), p + Vector2(8, -8), sackDark, 1.2)


func drawTradeBoard(center: Vector2) -> void:
	var post: Color = Color(0.24, 0.14, 0.08, 0.9)
	var board: Color = Color(0.60, 0.42, 0.22, 0.9)
	var paper: Color = Color(0.86, 0.76, 0.54, 0.85)
	var mark: Color = Color(0.18, 0.12, 0.08, 0.8)
	
	var boardCenter: Vector2 = center + Vector2(-118, -22)
	
	draw_rect(Rect2(boardCenter + Vector2(-4, -8), Vector2(8, 72)), post, true)
	
	var boardRect := Rect2(boardCenter + Vector2(-34, -42), Vector2(68, 38))
	draw_rect(boardRect, board, true)
	draw_rect(boardRect, post, false, 1.5)
	
	var paperA := Rect2(boardRect.position + Vector2(7, 7), Vector2(22, 24))
	var paperB := Rect2(boardRect.position + Vector2(36, 9), Vector2(22, 20))
	
	draw_rect(paperA, paper, true)
	draw_rect(paperB, paper, true)
	
	draw_line(paperA.position + Vector2(4, 7), paperA.position + Vector2(17, 7), mark, 1.0)
	draw_line(paperA.position + Vector2(4, 14), paperA.position + Vector2(14, 14), mark, 1.0)
	draw_line(paperB.position + Vector2(4, 6), paperB.position + Vector2(16, 6), mark, 1.0)


func drawRouteMarkers(worldRect: Rect2) -> void:
	var rope: Color = Color(0.82, 0.68, 0.42, ropeAlpha)
	var post: Color = Color(0.30, 0.18, 0.10, ropeAlpha)
	
	# 외부 길/물류 지점 느낌을 위한 약한 경계 말뚝
	var points: Array[Vector2] = [
		worldRect.position + Vector2(10, 8),
		worldRect.position + Vector2(worldRect.size.x - 10, 8),
		worldRect.position + Vector2(10, worldRect.size.y - 8),
		worldRect.position + Vector2(worldRect.size.x - 10, worldRect.size.y - 8)
	]
	
	for p in points:
		draw_circle(p, 5.0, post)
	
	draw_line(points[0], points[1], rope, 1.5)
	draw_line(points[2], points[3], rope, 1.5)


func pseudoRandomPointInRect(rect: Rect2, index: int) -> Vector2:
	var x: float = rect.position.x + rand01(index * 17 + 5) * rect.size.x
	var y: float = rect.position.y + rand01(index * 31 + 11) * rect.size.y
	return Vector2(x, y)


func rand01(value: int) -> float:
	var raw: int = int(abs(hash(str(value)))) % 10000
	return float(raw) / 10000.0


func randRange(value: int, minValue: float, maxValue: float) -> float:
	return lerp(minValue, maxValue, rand01(value))
