extends Node2D
class_name RuinedGardenAndWestFieldDebugRenderer

@export var renderEnabled: bool = true

@export var ruinedGardenAreaId: String = "ruined_garden_area"
@export var westFieldAreaId: String = "west_field_expansion_area"

@export var zIndexValue: int = -76
@export var ruinedAlpha: float = 0.72
@export var fieldAlpha: float = 0.55

@export var brokenFenceCount: int = 10
@export var oldPlotCount: int = 7
@export var fieldPatchCount: int = 34
@export var seedValue: int = 13579

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("ruined_garden_west_field_debug_renderer")
	z_index = zIndexValue
	refreshReferences()
	print("RuinedGardenAndWestFieldDebugRenderer ready.")
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
	
	drawRuinedGarden()
	drawWestField()


func drawRuinedGarden() -> void:
	if not worldAreaManager.hasArea(ruinedGardenAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(ruinedGardenAreaId)
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue
	
	# 오래된 정원 바닥: 마른 흙 + 희미한 화단 흔적
	draw_rect(rect.grow(-10.0), Color(0.52, 0.40, 0.22, ruinedAlpha * 0.34), true)
	draw_rect(rect.grow(-10.0), Color(0.76, 0.60, 0.32, ruinedAlpha * 0.30), false, 2.0)
	
	drawOldGardenPlots(rect, rng)
	drawBrokenFenceBits(rect, rng)
	drawForgottenGardenMarks(rect, rng)


func drawOldGardenPlots(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var plotColor: Color = Color(0.42, 0.28, 0.15, ruinedAlpha * 0.55)
	var plotEdge: Color = Color(0.82, 0.66, 0.35, ruinedAlpha * 0.35)
	
	for i in range(oldPlotCount):
		var w: float = rng.randf_range(80.0, 150.0)
		var h: float = rng.randf_range(34.0, 58.0)
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 18.0, rect.position.x + rect.size.x - w - 18.0),
			rng.randf_range(rect.position.y + 18.0, rect.position.y + rect.size.y - h - 18.0)
		)
		
		var plotRect := Rect2(p, Vector2(w, h))
		draw_rect(plotRect, plotColor, true)
		draw_rect(plotRect, plotEdge, false, 1.5)
		
		# 예전 고랑 흔적
		for r in range(1, 4):
			var y: float = plotRect.position.y + float(r) * plotRect.size.y / 4.0
			draw_line(
				Vector2(plotRect.position.x + 6.0, y),
				Vector2(plotRect.position.x + plotRect.size.x - 6.0, y),
				Color(0.25, 0.17, 0.10, ruinedAlpha * 0.35),
				1.0
			)


func drawBrokenFenceBits(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var wood: Color = Color(0.42, 0.25, 0.13, ruinedAlpha)
	var dark: Color = Color(0.18, 0.10, 0.06, ruinedAlpha * 0.85)
	
	for i in range(brokenFenceCount):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 10.0, rect.position.x + rect.size.x - 10.0),
			rng.randf_range(rect.position.y + 10.0, rect.position.y + rect.size.y - 10.0)
		)
		
		var angle: float = rng.randf_range(-0.8, 0.8)
		var len: float = rng.randf_range(28.0, 54.0)
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		
		draw_line(p + Vector2(1.5, 2.0), p + dir * len + Vector2(1.5, 2.0), dark, 5.0)
		draw_line(p, p + dir * len, wood, 4.0)
		
		if i % 2 == 0:
			draw_circle(p, 4.0, dark)


func drawForgottenGardenMarks(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var paleFlower: Color = Color(0.95, 0.82, 0.55, ruinedAlpha * 0.55)
	var dryStem: Color = Color(0.64, 0.50, 0.26, ruinedAlpha * 0.55)
	var stone: Color = Color(0.45, 0.43, 0.38, ruinedAlpha * 0.55)
	
	for i in range(42):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 8.0, rect.position.x + rect.size.x - 8.0),
			rng.randf_range(rect.position.y + 8.0, rect.position.y + rect.size.y - 8.0)
		)
		
		if i % 5 == 0:
			draw_circle(p, rng.randf_range(2.0, 4.5), stone)
		elif i % 3 == 0:
			draw_line(p, p + Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-9.0, -4.0)), dryStem, 1.2)
			draw_circle(p + Vector2(0, -7), 2.0, paleFlower)
		else:
			draw_line(p, p + Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-2.0, 2.0)), dryStem, 1.0)


func drawWestField() -> void:
	if not worldAreaManager.hasArea(westFieldAreaId):
		return
	
	var rect: Rect2 = worldAreaManager.getAreaWorldRect(westFieldAreaId)
	var rng := RandomNumberGenerator.new()
	rng.seed = seedValue + 1000
	
	# 넓은 들판: 정원보다 덜 구조적이고, 긴 풀/완만한 패치 중심
	draw_rect(rect.grow(-8.0), Color(0.58, 0.52, 0.26, fieldAlpha * 0.22), true)
	draw_rect(rect.grow(-8.0), Color(0.90, 0.76, 0.38, fieldAlpha * 0.22), false, 1.5)
	
	drawFieldGrassPatches(rect, rng)
	drawFieldOpenSpaceHints(rect, rng)


func drawFieldGrassPatches(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var grassA: Color = Color(0.54, 0.62, 0.28, fieldAlpha * 0.72)
	var grassB: Color = Color(0.72, 0.62, 0.28, fieldAlpha * 0.62)
	var grassDark: Color = Color(0.32, 0.42, 0.18, fieldAlpha * 0.55)
	
	for i in range(fieldPatchCount):
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 12.0, rect.position.x + rect.size.x - 12.0),
			rng.randf_range(rect.position.y + 12.0, rect.position.y + rect.size.y - 12.0)
		)
		
		var bladeCount: int = rng.randi_range(4, 9)
		var baseLen: float = rng.randf_range(10.0, 24.0)
		
		for j in range(bladeCount):
			var angle: float = rng.randf_range(-1.2, -0.1)
			var length: float = baseLen * rng.randf_range(0.55, 1.15)
			var end: Vector2 = p + Vector2(cos(angle) * length, sin(angle) * length)
			var color: Color = grassA if j % 2 == 0 else grassB
			draw_line(p, end, color, 1.4)
		
		if i % 4 == 0:
			draw_circle(p + Vector2(2, 1), rng.randf_range(3.0, 6.0), grassDark)


func drawFieldOpenSpaceHints(rect: Rect2, rng: RandomNumberGenerator) -> void:
	# 미래 농지 확장 후보 느낌: 아주 희미한 경계/평탄한 공간 표시
	var hint: Color = Color(0.95, 0.80, 0.36, fieldAlpha * 0.25)
	
	for i in range(3):
		var w: float = rng.randf_range(180.0, 300.0)
		var h: float = rng.randf_range(80.0, 130.0)
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x + 24.0, rect.position.x + rect.size.x - w - 24.0),
			rng.randf_range(rect.position.y + 24.0, rect.position.y + rect.size.y - h - 24.0)
		)
		
		draw_rect(Rect2(p, Vector2(w, h)), hint, false, 1.5)
