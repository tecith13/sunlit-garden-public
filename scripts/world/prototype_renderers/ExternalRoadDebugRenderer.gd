extends Node2D
class_name ExternalRoadDebugRenderer

@export var renderEnabled: bool = true
@export var roadAreaId: String = "external_road_area"

@export var zIndexValue: int = -82
@export var roadAlpha: float = 0.78
@export var markerAlpha: float = 0.9

@export var pebbleCount: int = 90
@export var seedValue: int = 86420

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("external_road_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("ExternalRoadDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshRoad() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	if not worldAreaManager.hasArea(roadAreaId):
		return
	
	drawExternalRoad()


func drawExternalRoad() -> void:
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(roadAreaId)
	
	drawRoadBody(worldRect)
	drawRoadPebbles(worldRect)
	drawRoutePosts(worldRect)
	drawExitHint(worldRect)


func drawRoadBody(worldRect: Rect2) -> void:
	var dirtColor: Color = Color(0.48, 0.34, 0.19, roadAlpha)
	var packedColor: Color = Color(0.62, 0.48, 0.28, roadAlpha * 0.55)
	var shadowColor: Color = Color(0.25, 0.17, 0.10, roadAlpha * 0.55)
	
	var topCenter: Vector2 = Vector2(worldRect.position.x + worldRect.size.x * 0.5, worldRect.position.y)
	var bottomCenter: Vector2 = Vector2(worldRect.position.x + worldRect.size.x * 0.5, worldRect.position.y + worldRect.size.y)
	
	var leftPoints := PackedVector2Array()
	var rightPoints := PackedVector2Array()
	var segments: int = 16
	
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var y: float = lerp(topCenter.y, bottomCenter.y, t)
		
		var wave: float = sin(t * PI * 1.5 + 0.8) * 18.0
		var centerX: float = topCenter.x + wave
		
		var width: float = lerp(worldRect.size.x * 0.55, worldRect.size.x * 0.95, t)
		var halfWidth: float = width * 0.5
		
		leftPoints.append(Vector2(centerX - halfWidth, y))
		rightPoints.append(Vector2(centerX + halfWidth, y))
	
	var poly := PackedVector2Array()
	for p in leftPoints:
		poly.append(p)
	for i in range(rightPoints.size() - 1, -1, -1):
		poly.append(rightPoints[i])
	
	draw_polygon(poly, PackedColorArray([dirtColor]))
	
	# 길 중앙의 다져진 부분
	var innerRect: Rect2 = worldRect.grow(-18.0)
	draw_rect(innerRect, packedColor, true)
	
	# 아래쪽으로 갈수록 외부로 열리는 그림자
	draw_rect(
		Rect2(
			Vector2(worldRect.position.x, worldRect.position.y + worldRect.size.y * 0.74),
			Vector2(worldRect.size.x, worldRect.size.y * 0.26)
		),
		shadowColor,
		true
	)


func drawRoadPebbles(worldRect: Rect2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	var pebbleColorA: Color = Color(0.68, 0.57, 0.38, markerAlpha * 0.7)
	var pebbleColorB: Color = Color(0.38, 0.32, 0.25, markerAlpha * 0.55)
	
	for i in range(pebbleCount):
		var p: Vector2 = Vector2(
			rng.randf_range(worldRect.position.x + 6.0, worldRect.position.x + worldRect.size.x - 6.0),
			rng.randf_range(worldRect.position.y + 6.0, worldRect.position.y + worldRect.size.y - 6.0)
		)
		
		var radius: float = rng.randf_range(1.5, 4.5)
		var color: Color = pebbleColorA if i % 2 == 0 else pebbleColorB
		
		draw_circle(p, radius, color)


func drawRoutePosts(worldRect: Rect2) -> void:
	var postColor: Color = Color(0.31, 0.19, 0.10, markerAlpha)
	var ropeColor: Color = Color(0.82, 0.68, 0.42, markerAlpha * 0.65)
	var signColor: Color = Color(0.66, 0.48, 0.25, markerAlpha)
	var markColor: Color = Color(0.18, 0.12, 0.08, markerAlpha * 0.85)
	
	var leftX: float = worldRect.position.x + 12.0
	var rightX: float = worldRect.position.x + worldRect.size.x - 12.0
	
	var postYs: Array[float] = [
		worldRect.position.y + 18.0,
		worldRect.position.y + worldRect.size.y * 0.45,
		worldRect.position.y + worldRect.size.y - 20.0
	]
	
	var leftPosts: Array[Vector2] = []
	var rightPosts: Array[Vector2] = []
	
	for y in postYs:
		var lp: Vector2 = Vector2(leftX, y)
		var rp: Vector2 = Vector2(rightX, y)
		leftPosts.append(lp)
		rightPosts.append(rp)
		draw_circle(lp, 5.0, postColor)
		draw_circle(rp, 5.0, postColor)
	
	for i in range(leftPosts.size() - 1):
		draw_line(leftPosts[i], leftPosts[i + 1], ropeColor, 1.5)
		draw_line(rightPosts[i], rightPosts[i + 1], ropeColor, 1.5)
	
	# 작은 방향 표지판
	var signPos: Vector2 = Vector2(rightX - 32.0, worldRect.position.y + 28.0)
	draw_rect(Rect2(signPos + Vector2(-3, -4), Vector2(6, 42)), postColor, true)
	
	var signRect := Rect2(signPos + Vector2(-42, -24), Vector2(62, 22))
	draw_rect(signRect, signColor, true)
	draw_rect(signRect, postColor, false, 1.5)
	
	# 화살표 느낌
	draw_line(signRect.position + Vector2(10, 11), signRect.position + Vector2(44, 11), markColor, 2.0)
	draw_line(signRect.position + Vector2(44, 11), signRect.position + Vector2(34, 5), markColor, 2.0)
	draw_line(signRect.position + Vector2(44, 11), signRect.position + Vector2(34, 17), markColor, 2.0)


func drawExitHint(worldRect: Rect2) -> void:
	# 아래쪽 끝을 살짝 밝게 열어서, 이 길이 바깥으로 이어진다는 느낌.
	var glowColor: Color = Color(1.0, 0.82, 0.42, 0.18)
	var edgeColor: Color = Color(0.95, 0.75, 0.36, 0.35)
	
	var exitRect := Rect2(
		Vector2(worldRect.position.x - 12.0, worldRect.position.y + worldRect.size.y - 28.0),
		Vector2(worldRect.size.x + 24.0, 36.0)
	)
	
	draw_rect(exitRect, glowColor, true)
	draw_line(
		Vector2(exitRect.position.x, exitRect.position.y + exitRect.size.y - 4.0),
		Vector2(exitRect.position.x + exitRect.size.x, exitRect.position.y + exitRect.size.y - 4.0),
		edgeColor,
		2.0
	)
