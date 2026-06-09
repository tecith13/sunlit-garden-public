extends Node2D
class_name SeedStallAreaDebugRenderer

@export var renderEnabled: bool = true
@export var stallAreaId: String = "seed_stall_area"

@export var zIndexValue: int = -60
@export var baseAlpha: float = 0.85
@export var woodAlpha: float = 0.95
@export var clothAlpha: float = 0.92

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("seed_stall_area_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("SeedStallAreaDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshStall() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	if not worldAreaManager.hasArea(stallAreaId):
		return
	
	drawSeedStallArea()


func drawSeedStallArea() -> void:
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(stallAreaId)
	var center: Vector2 = worldRect.position + worldRect.size * 0.5
	
	drawGroundPatch(worldRect)
	drawStall(center)
	drawSeedCrates(center)
	drawSmallSign(center)
	drawBoundaryHints(worldRect)


func drawGroundPatch(worldRect: Rect2) -> void:
	var dirtColor: Color = Color(0.46, 0.34, 0.20, baseAlpha * 0.55)
	var strawColor: Color = Color(0.72, 0.58, 0.30, baseAlpha * 0.35)
	
	var groundRect: Rect2 = worldRect.grow(-8.0)
	draw_rect(groundRect, dirtColor, true)
	draw_rect(groundRect, Color(0.30, 0.23, 0.16, baseAlpha * 0.65), false, 2.0)
	
	for i in range(18):
		var p: Vector2 = pseudoRandomPointInRect(groundRect, i)
		draw_line(
			p,
			p + Vector2(randRange(i, -7.0, 7.0), randRange(i + 31, -2.0, 2.0)),
			strawColor,
			1.0
		)


func drawStall(center: Vector2) -> void:
	var woodColor: Color = Color(0.48, 0.29, 0.16, woodAlpha)
	var darkWood: Color = Color(0.25, 0.16, 0.10, woodAlpha)
	var clothA: Color = Color(0.88, 0.72, 0.42, clothAlpha)
	var clothB: Color = Color(0.95, 0.86, 0.58, clothAlpha)
	var clothShadow: Color = Color(0.50, 0.36, 0.20, clothAlpha * 0.45)
	
	# 가판대 본체
	var counterRect := Rect2(center + Vector2(-74, -8), Vector2(148, 34))
	draw_rect(counterRect, woodColor, true)
	draw_rect(counterRect, darkWood, false, 2.0)
	
	# 하단 다리
	draw_rect(Rect2(counterRect.position + Vector2(12, 30), Vector2(10, 34)), darkWood, true)
	draw_rect(Rect2(counterRect.position + Vector2(counterRect.size.x - 22, 30), Vector2(10, 34)), darkWood, true)
	
	# 천막 지지대
	draw_rect(Rect2(center + Vector2(-68, -72), Vector2(8, 70)), darkWood, true)
	draw_rect(Rect2(center + Vector2(60, -72), Vector2(8, 70)), darkWood, true)
	
	# 천막
	var awningRect := Rect2(center + Vector2(-86, -78), Vector2(172, 38))
	draw_rect(awningRect, clothB, true)
	
	var stripeWidth: float = awningRect.size.x / 5.0
	for i in range(5):
		if i % 2 == 0:
			draw_rect(
				Rect2(awningRect.position + Vector2(stripeWidth * i, 0), Vector2(stripeWidth, awningRect.size.y)),
				clothA,
				true
			)
	
	draw_rect(Rect2(awningRect.position + Vector2(0, awningRect.size.y - 7), Vector2(awningRect.size.x, 7)), clothShadow, true)
	draw_rect(awningRect, darkWood, false, 2.0)
	
	# 천막 아래 작은 물결 장식
	for i in range(6):
		var x: float = awningRect.position.x + 12.0 + i * 26.0
		draw_arc(
			Vector2(x, awningRect.position.y + awningRect.size.y - 2.0),
			9.0,
			0.0,
			PI,
			10,
			clothShadow,
			1.2
		)


func drawSeedCrates(center: Vector2) -> void:
	var crateColor: Color = Color(0.54, 0.34, 0.18, 0.95)
	var crateDark: Color = Color(0.25, 0.16, 0.10, 0.85)
	var seedGreen: Color = Color(0.45, 0.72, 0.28, 0.95)
	var seedTan: Color = Color(0.78, 0.62, 0.32, 0.95)
	
	var cratePositions: Array[Vector2] = [
		center + Vector2(-54, -2),
		center + Vector2(-10, -4),
		center + Vector2(36, -2),
		center + Vector2(-86, 36),
		center + Vector2(74, 34)
	]
	
	for i in range(cratePositions.size()):
		var p: Vector2 = cratePositions[i]
		var r := Rect2(p, Vector2(30, 22))
		
		draw_rect(r, crateColor, true)
		draw_rect(r, crateDark, false, 1.5)
		draw_line(r.position + Vector2(0, 8), r.position + Vector2(r.size.x, 8), crateDark, 1.0)
		
		var seedColor: Color = seedGreen if i % 2 == 0 else seedTan
		for j in range(5):
			var seedPos: Vector2 = r.position + Vector2(5 + j * 5, 5 + (j % 2) * 4)
			draw_circle(seedPos, 2.0, seedColor)


func drawSmallSign(center: Vector2) -> void:
	var postColor: Color = Color(0.29, 0.18, 0.10, 0.9)
	var signColor: Color = Color(0.72, 0.56, 0.30, 0.9)
	var markColor: Color = Color(0.20, 0.14, 0.08, 0.75)
	
	var signCenter: Vector2 = center + Vector2(-104, 4)
	
	draw_rect(Rect2(signCenter + Vector2(-3, -4), Vector2(6, 54)), postColor, true)
	
	var signRect := Rect2(signCenter + Vector2(-26, -26), Vector2(52, 24))
	draw_rect(signRect, signColor, true)
	draw_rect(signRect, postColor, false, 1.5)
	
	# 씨앗 주머니 느낌의 간단한 표시
	draw_circle(signRect.position + Vector2(16, 12), 5.0, markColor)
	draw_line(signRect.position + Vector2(27, 8), signRect.position + Vector2(42, 8), markColor, 1.5)
	draw_line(signRect.position + Vector2(27, 15), signRect.position + Vector2(39, 15), markColor, 1.5)


func drawBoundaryHints(worldRect: Rect2) -> void:
	var hintColor: Color = Color(0.95, 0.82, 0.45, 0.35)
	var cornerSize: float = 18.0
	
	var corners: Array[Vector2] = [
		worldRect.position,
		worldRect.position + Vector2(worldRect.size.x, 0),
		worldRect.position + Vector2(0, worldRect.size.y),
		worldRect.position + worldRect.size
	]
	
	for c in corners:
		draw_circle(c, 4.5, hintColor)
	
	# 부지 감각을 약하게만 표시
	draw_rect(worldRect.grow(-4.0), hintColor, false, 1.5)


func pseudoRandomPointInRect(rect: Rect2, index: int) -> Vector2:
	var x: float = rect.position.x + rand01(index * 17 + 3) * rect.size.x
	var y: float = rect.position.y + rand01(index * 31 + 9) * rect.size.y
	return Vector2(x, y)


func rand01(value: int) -> float:
	var raw: int = int(abs(hash(str(value)))) % 10000
	return float(raw) / 10000.0


func randRange(value: int, minValue: float, maxValue: float) -> float:
	return lerp(minValue, maxValue, rand01(value))
