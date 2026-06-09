extends Node2D
class_name WorldAreaDebugDrawer

@export var debugVisible: bool = true

var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null

var areaColors: Dictionary = {
	"starter_region": Color(1.0, 1.0, 1.0, 0.04),

	"player_home_area": Color(0.3, 1.0, 0.4, 0.16),
	"house_plot": Color(1.0, 0.85, 0.2, 0.18),
	"ruined_garden_area": Color(0.65, 0.45, 0.2, 0.20),
	"west_field_expansion_area": Color(0.7, 0.55, 0.2, 0.16),

	"mailbox_area": Color(1.0, 0.6, 0.15, 0.28),
	"back_forest_area": Color(0.1, 0.65, 0.25, 0.20),
	"blocked_old_path_area": Color(0.25, 0.45, 0.15, 0.28),
	"archive_route_area": Color(0.35, 0.75, 0.45, 0.20),

	"old_stone_road_area": Color(0.9, 0.9, 0.45, 0.18),
	"village_square_area": Color(0.8, 0.55, 1.0, 0.20),
	"seed_stall_area": Color(1.0, 0.8, 0.25, 0.24),
	"shipping_trade_area": Color(0.95, 0.55, 0.25, 0.24),
	"furniture_workshop_area": Color(0.6, 0.35, 1.0, 0.22),
	"temporary_housing_area": Color(1.0, 0.55, 0.85, 0.18),
	"teahouse_area": Color(0.55, 0.9, 0.65, 0.20),
	"external_road_area": Color(1.0, 1.0, 0.25, 0.18),

	"brook_area": Color(0.2, 0.55, 1.0, 0.20),
	"mineral_fragment_area": Color(0.4, 0.75, 1.0, 0.26),
	"east_gathering_area": Color(0.25, 0.85, 0.55, 0.16)
}


func _ready() -> void:
	add_to_group("world_area_debug_drawer")
	refreshReferences()
	print("WorldAreaDebugDrawer ready.")


func _process(_delta: float) -> void:
	if debugVisible:
		queue_redraw()


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func _draw() -> void:
	if not debugVisible:
		return
	
	refreshReferences()
	
	if worldAreaManager == null or worldGrid == null:
		return
	
	for areaId in worldAreaManager.getAreaIds():
		drawArea(areaId)


func drawArea(areaId: String) -> void:
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(areaId)
	
	var fillColor: Color = Color(1.0, 1.0, 1.0, 0.12)
	if areaColors.has(areaId):
		fillColor = areaColors[areaId]
	
	var borderColor: Color = fillColor
	borderColor.a = min(fillColor.a + 0.35, 0.8)
	
	draw_rect(worldRect, fillColor, true)
	draw_rect(worldRect, borderColor, false, 2.0)
	
	drawAreaLabel(areaId, worldRect.position + Vector2(8, 18), borderColor)


func drawAreaLabel(areaId: String, position: Vector2, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	
	draw_string(
		font,
		position,
		areaId,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		14,
		color
	)
