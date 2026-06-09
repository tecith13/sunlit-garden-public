extends Node2D
class_name TerrainDebugDrawer

@export var debugVisible: bool = true
@export var drawCellSize: int = 16
@export var drawEveryNCells: int = 8
@export var drawLabels: bool = false
@export var drawConnectors: bool = true

var terrainManager: TerrainManager = null
var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("terrain_debug_drawer")
	refreshReferences()
	print("TerrainDebugDrawer ready.")
	queue_redraw()


#func _process(_delta: float) -> void:
	#if debugVisible:
		#queue_redraw()


func refreshDebugDraw() -> void:
	refreshReferences()
	queue_redraw()


func refreshReferences() -> void:
	if terrainManager == null:
		terrainManager = get_tree().get_first_node_in_group("terrain_manager")
	
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func _draw() -> void:
	if not debugVisible:
		return
	
	refreshReferences()
	
	if terrainManager == null or worldAreaManager == null or worldGrid == null:
		return
	
	drawTerrainCells()
	
	if drawConnectors:
		drawHeightConnectors()


func drawTerrainCells() -> void:
	var starterRect: Rect2i = worldAreaManager.getAreaRect("starter_region")
	
	for y in range(starterRect.position.y, starterRect.position.y + starterRect.size.y, drawEveryNCells):
		for x in range(starterRect.position.x, starterRect.position.x + starterRect.size.x, drawEveryNCells):
			var cell: Vector2i = Vector2i(x, y)
			var data: Dictionary = terrainManager.getTerrainCell(cell)
			
			drawTerrainCell(cell, data)


func drawTerrainCell(cell: Vector2i, data: Dictionary) -> void:
	var worldPos: Vector2 = worldGrid.cell_to_world(cell)
	var size: Vector2 = Vector2(
		drawCellSize * drawEveryNCells,
		drawCellSize * drawEveryNCells
	)
	
	var rect: Rect2 = Rect2(worldPos, size)
	var color: Color = getTerrainDebugColor(data)
	
	draw_rect(rect, color, true)
	
	if bool(data.get("blocked", false)):
		draw_rect(rect, Color(1.0, 0.1, 0.1, 0.65), false, 2.0)
	
	if drawLabels:
		drawCellLabel(cell, data, worldPos + Vector2(2, 12))


func getTerrainDebugColor(data: Dictionary) -> Color:
	var terrainId: String = str(data.get("terrainId", "grass"))
	var height: int = int(data.get("height", 0))
	var water: bool = bool(data.get("water", false))
	var blocked: bool = bool(data.get("blocked", false))
	
	if water:
		return Color(0.1, 0.45, 1.0, 0.35)
	
	if blocked:
		return Color(0.75, 0.1, 0.1, 0.28)
	
	match terrainId:
		"forest_floor":
			return Color(0.05, 0.45, 0.18, 0.24)
		"forest_path_blocked":
			return Color(0.2, 0.3, 0.12, 0.32)
		"dry_grass":
			return Color(0.75, 0.55, 0.2, 0.24)
		"stone_ground":
			return Color(0.65, 0.6, 0.75, 0.26)
		"rocky_ground":
			return Color(0.45, 0.5, 0.6, 0.30)
		"wild_grass":
			return Color(0.25, 0.75, 0.35, 0.22)
		"dirt":
			return Color(0.65, 0.38, 0.18, 0.24)
		_:
			if height > 0:
				return Color(0.7, 0.55, 1.0, 0.20)
			elif height < 0:
				return Color(0.2, 0.45, 0.9, 0.22)
			else:
				return Color(0.25, 0.8, 0.3, 0.12)


func drawCellLabel(cell: Vector2i, data: Dictionary, position: Vector2) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	
	var height: int = int(data.get("height", 0))
	var terrainId: String = str(data.get("terrainId", ""))
	var labelText: String = "%s h%d" % [terrainId, height]
	
	draw_string(
		font,
		position,
		labelText,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		10,
		Color(1.0, 1.0, 1.0, 0.8)
	)


func drawHeightConnectors() -> void:
	for connectorKey in terrainManager.heightConnectors.keys():
		var parts: PackedStringArray = str(connectorKey).split("|")
		if parts.size() != 2:
			continue
		
		var cell: Vector2i = terrainManager.parseCellKey(parts[0])
		var direction: String = parts[1]
		var targetCell: Vector2i = terrainManager.getNeighborCell(cell, direction)
		
		var fromPos: Vector2 = worldGrid.cell_to_world_center(cell)
		var toPos: Vector2 = worldGrid.cell_to_world_center(targetCell)
		
		draw_line(fromPos, toPos, Color(1.0, 1.0, 0.0, 0.9), 4.0)
		draw_circle(fromPos, 5.0, Color(1.0, 1.0, 0.0, 0.9))
