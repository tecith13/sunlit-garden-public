extends Node2D
class_name EastGatheringAndMineralDebugRenderer

@export var renderEnabled: bool = true

@export var eastGatheringAreaId: String = "east_gathering_area"
@export var mineralFragmentAreaId: String = "mineral_fragment_area"

@export var zIndexValue: int = -56
@export var gatheringAlpha: float = 0.78
@export var mineralAlpha: float = 0.92

@export var herbPatchCount: int = 28
@export var flowerPatchCount: int = 18
@export var stoneClusterCount: int = 16
@export var seedValue: int = 42424

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("east_gathering_mineral_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("EastGatheringAndMineralDebugRenderer ready.")
	queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func refreshRenderer() -> void:
	refreshReferences()
	queue_redraw()


func _draw() -> void:
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	drawEastGatheringArea()
	drawMineralFragmentArea()


func drawEastGatheringArea() -> void:
	if not worldAreaManager.hasArea(eastGatheringAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(eastGatheringAreaId)
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	# 개울가 주변의 자연 채집 구역: 젖은 풀, 작은 꽃, 허브 느낌
	draw_rect(rect.grow(-8.0), Color(0.18, 0.42, 0.24, gatheringAlpha * 0.24), true)
	draw_rect(rect.grow(-8.0), Color(0.44, 0.74, 0.38, gatheringAlpha * 0.28), false, 1.5)
	
	drawHerbPatches(rect, rng)
	drawFlowerPatches(rect, rng)
	drawGatheringGroundMarks(rect, rng)


func drawHerbPatches(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var stemColor: Color = Color(0.18, 0.48, 0.18, gatheringAlpha)
	var leafColor: Color = Color(0.34, 0.72, 0.28, gatheringAlpha)
	var darkLeaf: Color = Color(0.12, 0.34, 0.12, gatheringAlpha * 0.8)
	
	for i in range(herbPatchCount):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 10.0, rect.position.x + rect.size.x - 10.0),
			rng.randf_range(rect.position.y + 10.0, rect.position.y + rect.size.y - 10.0)
		)
		
		var blades: int = rng.randi_range(3, 7)
		
		for j in range(blades):
			var angle: float = rng.randf_range(-1.9, -1.1)
			var len: float = rng.randf_range(9.0, 18.0)
			var end: Vector2 = p + Vector2(cos(angle) * len, sin(angle) * len)
			
			draw_line(p, end, stemColor, 1.4)
			draw_circle(end, rng.randf_range(2.0, 3.8), leafColor if j % 2 == 0 else darkLeaf)
		
		if i % 4 == 0:
			draw_circle(p + Vector2(2, 2), 4.0, Color(0.07, 0.20, 0.08, gatheringAlpha * 0.35))


func drawFlowerPatches(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var stemColor: Color = Color(0.22, 0.48, 0.18, gatheringAlpha * 0.85)
	var flowerA: Color = Color(0.92, 0.76, 0.42, gatheringAlpha)
	var flowerB: Color = Color(0.78, 0.58, 0.92, gatheringAlpha * 0.9)
	var flowerC: Color = Color(0.95, 0.86, 0.68, gatheringAlpha)
	
	for i in range(flowerPatchCount):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 12.0, rect.position.x + rect.size.x - 12.0),
			rng.randf_range(rect.position.y + 12.0, rect.position.y + rect.size.y - 12.0)
		)
		
		var count: int = rng.randi_range(2, 5)
		
		for j in range(count):
			var offset: Vector2 = Vector2(rng.randf_range(-8.0, 8.0), rng.randf_range(-5.0, 6.0))
			var base: Vector2 = p + offset
			var top: Vector2 = base + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-12.0, -7.0))
			
			draw_line(base, top, stemColor, 1.0)
			
			var color: Color = flowerA
			if (i + j) % 3 == 1:
				color = flowerB
			elif (i + j) % 3 == 2:
				color = flowerC
			
			drawFlower(top, color)


func drawFlower(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(-2, 0), 2.0, color)
	draw_circle(pos + Vector2(2, 0), 2.0, color)
	draw_circle(pos + Vector2(0, -2), 2.0, color)
	draw_circle(pos + Vector2(0, 2), 2.0, color)
	draw_circle(pos, 1.5, Color(0.78, 0.55, 0.22, color.a))


func drawGatheringGroundMarks(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var wetMark: Color = Color(0.18, 0.32, 0.22, gatheringAlpha * 0.28)
	var smallStone: Color = Color(0.46, 0.48, 0.42, gatheringAlpha * 0.55)
	
	for i in range(36):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 8.0, rect.position.x + rect.size.x - 8.0),
			rng.randf_range(rect.position.y + 8.0, rect.position.y + rect.size.y - 8.0)
		)
		
		if i % 3 == 0:
			draw_circle(p, rng.randf_range(3.0, 7.0), wetMark)
		else:
			draw_circle(p, rng.randf_range(1.5, 3.5), smallStone)


func drawMineralFragmentArea() -> void:
	if not worldAreaManager.hasArea(mineralFragmentAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(mineralFragmentAreaId)
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue + 999
	
	# 광물 발견 후보지: 개울가 북동쪽의 작고 특이한 바위 지대
	draw_rect(rect.grow(-6.0), Color(0.32, 0.36, 0.38, mineralAlpha * 0.42), true)
	draw_rect(rect.grow(-6.0), Color(0.68, 0.72, 0.76, mineralAlpha * 0.45), false, 1.5)
	
	drawStoneClusters(rect, rng)
	drawSpecialMineralFragment(rect)


func drawStoneClusters(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var stoneA: Color = Color(0.42, 0.44, 0.46, mineralAlpha)
	var stoneB: Color = Color(0.56, 0.58, 0.60, mineralAlpha)
	var shadow: Color = Color(0.14, 0.13, 0.12, mineralAlpha * 0.5)
	
	for i in range(stoneClusterCount):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 8.0, rect.position.x + rect.size.x - 8.0),
			rng.randf_range(rect.position.y + 8.0, rect.position.y + rect.size.y - 8.0)
		)
		
		var radius: float = rng.randf_range(4.0, 11.0)
		var color: Color = stoneA if i % 2 == 0 else stoneB
		
		draw_circle(p + Vector2(2.0, 2.5), radius, shadow)
		draw_circle(p, radius, color)
		
		if i % 5 == 0:
			draw_line(
				p + Vector2(-radius * 0.4, -radius * 0.2),
				p + Vector2(radius * 0.35, radius * 0.25),
				Color(0.82, 0.84, 0.78, mineralAlpha * 0.45),
				1.0
			)


func drawSpecialMineralFragment(rect: Rect2) -> void:
	var center: Vector2 = rect.position + rect.size * 0.5
	
	var glow: Color = Color(0.65, 0.92, 1.0, 0.20)
	var mineral: Color = Color(0.62, 0.82, 0.92, mineralAlpha)
	var mineralDark: Color = Color(0.24, 0.34, 0.42, mineralAlpha)
	var shine: Color = Color(0.95, 1.0, 0.92, mineralAlpha * 0.8)
	
	draw_circle(center, 34.0, glow)
	
	var points := PackedVector2Array([
		center + Vector2(-8, -18),
		center + Vector2(12, -10),
		center + Vector2(16, 10),
		center + Vector2(2, 22),
		center + Vector2(-16, 8)
	])
	
	draw_polygon(points, PackedColorArray([mineral]))
	draw_polyline(points, mineralDark, 2.0, true)
	
	draw_line(center + Vector2(-3, -10), center + Vector2(8, 4), shine, 1.4)
	draw_line(center + Vector2(2, 8), center + Vector2(-6, 14), shine, 1.0)
	
	# 발견 후보 위치임을 아주 약하게 표시
	draw_arc(center, 42.0, 0.0, TAU, 32, Color(0.86, 0.92, 0.72, 0.24), 2.0)
