extends Node2D
class_name FutureVillageLotDebugRenderer

@export var renderEnabled: bool = true

@export var furnitureWorkshopAreaId: String = "furniture_workshop_area"
@export var temporaryHousingAreaId: String = "temporary_housing_area"
@export var teahouseAreaId: String = "teahouse_area"

@export var zIndexValue: int = -81
@export var lotAlpha: float = 0.58
@export var markerAlpha: float = 0.78

@export var seedValue: int = 77731

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("future_village_lot_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("FutureVillageLotDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshLots() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	drawFurnitureWorkshopLot()
	drawTemporaryHousingLot()
	drawTeahouseLot()


func drawFurnitureWorkshopLot() -> void:
	if not worldAreaManager.hasArea(furnitureWorkshopAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(furnitureWorkshopAreaId)
	
	drawLotGround(rect, Color(0.46, 0.34, 0.22, lotAlpha), Color(0.72, 0.54, 0.30, lotAlpha * 0.55))
	drawFoundationStones(rect, seedValue + 10)
	drawWoodPileHint(rect)
	drawCornerPosts(rect, Color(0.38, 0.23, 0.13, markerAlpha))
	drawLotLabelMark(rect, "workshop")


func drawTemporaryHousingLot() -> void:
	if not worldAreaManager.hasArea(temporaryHousingAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(temporaryHousingAreaId)
	
	drawLotGround(rect, Color(0.42, 0.36, 0.26, lotAlpha * 0.8), Color(0.78, 0.64, 0.42, lotAlpha * 0.45))
	drawFoundationStones(rect, seedValue + 40)
	drawEmptyHouseFootprints(rect)
	drawCornerPosts(rect, Color(0.32, 0.22, 0.14, markerAlpha * 0.8))
	drawLotLabelMark(rect, "housing")


func drawTeahouseLot() -> void:
	if not worldAreaManager.hasArea(teahouseAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(teahouseAreaId)
	
	drawLotGround(rect, Color(0.34, 0.42, 0.28, lotAlpha * 0.72), Color(0.66, 0.78, 0.48, lotAlpha * 0.38))
	drawFoundationStones(rect, seedValue + 80)
	drawRoundRestingHint(rect)
	drawCornerPosts(rect, Color(0.26, 0.20, 0.12, markerAlpha * 0.75))
	drawLotLabelMark(rect, "tea")


func drawLotGround(rect: Rect2, baseColor: Color, borderColor: Color) -> void:
	var inner: Rect2 = rect.grow(-8.0)
	
	draw_rect(inner, baseColor, true)
	draw_rect(inner, borderColor, false, 1.5)
	
	# 너무 완성된 건물터처럼 보이지 않도록 가장자리 흐트러짐
	for i in range(18):
		var p: Vector2 = pseudoRandomPointInRect(inner, i)
		draw_circle(p, randRange(i + 9, 2.0, 5.0), Color(0.25, 0.20, 0.14, baseColor.a * 0.35))


func drawFoundationStones(rect: Rect2, localSeed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = localSeed
	
	var stoneA: Color = Color(0.48, 0.46, 0.40, markerAlpha * 0.72)
	var stoneB: Color = Color(0.64, 0.60, 0.50, markerAlpha * 0.62)
	var shadow: Color = Color(0.18, 0.15, 0.12, markerAlpha * 0.35)
	
	var inner: Rect2 = rect.grow(-18.0)
	
	# 기초선처럼 보이는 가장자리 돌
	var points: Array[Vector2] = []
	
	for i in range(7):
		var t: float = float(i) / 6.0
		points.append(Vector2(lerp(inner.position.x, inner.position.x + inner.size.x, t), inner.position.y))
		points.append(Vector2(lerp(inner.position.x, inner.position.x + inner.size.x, t), inner.position.y + inner.size.y))
	
	for i in range(5):
		var t: float = float(i) / 4.0
		points.append(Vector2(inner.position.x, lerp(inner.position.y, inner.position.y + inner.size.y, t)))
		points.append(Vector2(inner.position.x + inner.size.x, lerp(inner.position.y, inner.position.y + inner.size.y, t)))
	
	for i in range(points.size()):
		var p: Vector2 = points[i] + Vector2(rng.randf_range(-5.0, 5.0), rng.randf_range(-5.0, 5.0))
		var r: float = rng.randf_range(3.0, 7.0)
		var color: Color = stoneA if i % 2 == 0 else stoneB
		
		draw_circle(p + Vector2(1.2, 1.8), r, shadow)
		draw_circle(p, r, color)


func drawWoodPileHint(rect: Rect2) -> void:
	var wood: Color = Color(0.48, 0.29, 0.14, markerAlpha)
	var dark: Color = Color(0.18, 0.10, 0.05, markerAlpha * 0.85)
	
	var base: Vector2 = rect.position + Vector2(rect.size.x * 0.58, rect.size.y * 0.58)
	
	for i in range(5):
		var start: Vector2 = base + Vector2(-32 + i * 12, i % 2 * 5)
		var end: Vector2 = start + Vector2(48, -8 + i % 3 * 4)
		
		draw_line(start + Vector2(1.5, 2.0), end + Vector2(1.5, 2.0), dark, 6.0)
		draw_line(start, end, wood, 5.0)
		draw_circle(start, 3.5, dark)
		draw_circle(end, 3.5, dark)


func drawEmptyHouseFootprints(rect: Rect2) -> void:
	var lineColor: Color = Color(0.86, 0.72, 0.46, markerAlpha * 0.38)
	var postColor: Color = Color(0.36, 0.24, 0.15, markerAlpha * 0.65)
	
	var footprintA := Rect2(rect.position + Vector2(22, 20), Vector2(rect.size.x * 0.35, rect.size.y * 0.38))
	var footprintB := Rect2(rect.position + Vector2(rect.size.x * 0.52, rect.size.y * 0.42), Vector2(rect.size.x * 0.34, rect.size.y * 0.36))
	
	drawFootprintRect(footprintA, lineColor, postColor)
	drawFootprintRect(footprintB, lineColor, postColor)


func drawFootprintRect(r: Rect2, lineColor: Color, postColor: Color) -> void:
	draw_rect(r, lineColor, false, 1.5)
	
	var corners: Array[Vector2] = [
		r.position,
		r.position + Vector2(r.size.x, 0),
		r.position + Vector2(0, r.size.y),
		r.position + r.size
	]
	
	for p in corners:
		draw_circle(p, 4.0, postColor)


func drawRoundRestingHint(rect: Rect2) -> void:
	var center: Vector2 = rect.position + rect.size * 0.5
	
	var ringColor: Color = Color(0.72, 0.62, 0.42, markerAlpha * 0.38)
	var tableColor: Color = Color(0.42, 0.28, 0.16, markerAlpha * 0.68)
	var mossColor: Color = Color(0.22, 0.42, 0.20, markerAlpha * 0.45)
	
	draw_circle(center, 42.0, mossColor)
	draw_arc(center, 42.0, 0.0, TAU, 32, ringColor, 2.0)
	
	# 아주 희미한 오래된 원형 자리. 아직 찻집은 아님.
	draw_circle(center, 12.0, tableColor)
	
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0 + 0.7
		var p: Vector2 = center + Vector2(cos(angle), sin(angle)) * 28.0
		draw_circle(p, 5.5, Color(0.34, 0.24, 0.16, markerAlpha * 0.55))


func drawCornerPosts(rect: Rect2, postColor: Color) -> void:
	var inner: Rect2 = rect.grow(-8.0)
	
	var corners: Array[Vector2] = [
		inner.position,
		inner.position + Vector2(inner.size.x, 0),
		inner.position + Vector2(0, inner.size.y),
		inner.position + inner.size
	]
	
	for p in corners:
		draw_circle(p, 4.5, postColor)


func drawLotLabelMark(rect: Rect2, lotType: String) -> void:
	# 실제 텍스트 대신 작은 상징만 그림. 개발 중 위치 구분용.
	var markColor: Color = Color(0.95, 0.82, 0.46, markerAlpha * 0.45)
	var dark: Color = Color(0.22, 0.14, 0.08, markerAlpha * 0.55)
	
	var p: Vector2 = rect.position + Vector2(18, 18)
	
	match lotType:
		"workshop":
			draw_rect(Rect2(p, Vector2(22, 12)), markColor, true)
			draw_line(p + Vector2(3, 9), p + Vector2(19, 3), dark, 1.5)
		"housing":
			var points := PackedVector2Array([
				p + Vector2(0, 12),
				p + Vector2(11, 0),
				p + Vector2(22, 12),
				p + Vector2(22, 24),
				p + Vector2(0, 24)
			])
			draw_polygon(points, PackedColorArray([markColor]))
			draw_polyline(points, dark, 1.2, true)
		"tea":
			draw_circle(p + Vector2(11, 12), 10.0, markColor)
			draw_arc(p + Vector2(23, 11), 8.0, -PI * 0.5, PI * 0.5, 12, dark, 1.5)
		_:
			draw_circle(p, 6.0, markColor)


func pseudoRandomPointInRect(rect: Rect2, index: int) -> Vector2:
	var x: float = rect.position.x + rand01(index * 17 + 5) * rect.size.x
	var y: float = rect.position.y + rand01(index * 31 + 11) * rect.size.y
	return Vector2(x, y)


func rand01(value: int) -> float:
	var raw: int = int(abs(hash(str(value)))) % 10000
	return float(raw) / 10000.0


func randRange(value: int, minValue: float, maxValue: float) -> float:
	return lerp(minValue, maxValue, rand01(value))
