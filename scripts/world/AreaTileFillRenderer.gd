extends Node2D
class_name AreaTileFillRenderer

@export var renderEnabled: bool = true
@export var areaId: String = "player_home_area"

@export var tileTexture: Texture2D
@export var tileSize: int = 64

# 너무 빽빽하면 무겁고 지저분해지므로 기본 128px 단위.
@export var alpha: float = 0.85
@export var zIndexValue: int = -100

@export var printDebug: bool = false

var worldAreaManager: WorldAreaManager = null


func _ready() -> void:
	add_to_group("area_tile_fill_renderer")
	z_index = zIndexValue
	
	refreshReferences()
	buildTiles()
	if printDebug: print("AreaTileFillRenderer ready. area:", areaId)


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func buildTiles() -> void:
	clearTiles()
	
	if not renderEnabled:
		return
	
	refreshReferences()
	
	if worldAreaManager == null:
		push_warning("AreaTileFillRenderer: WorldAreaManager is null.")
		return
	
	if tileTexture == null:
		push_warning("AreaTileFillRenderer: tileTexture is null.")
		return
	
	if not worldAreaManager.hasArea(areaId):
		push_warning("AreaTileFillRenderer: unknown areaId: " + areaId)
		return
	
	var worldRect: Rect2 = worldAreaManager.getAreaWorldRect(areaId)
	
	var startX: int = floori(worldRect.position.x / float(tileSize)) * tileSize
	var startY: int = floori(worldRect.position.y / float(tileSize)) * tileSize
	var endX: int = ceili((worldRect.position.x + worldRect.size.x) / float(tileSize)) * tileSize
	var endY: int = ceili((worldRect.position.y + worldRect.size.y) / float(tileSize)) * tileSize
	
	for y in range(startY, endY, tileSize):
		for x in range(startX, endX, tileSize):
			var tile := Sprite2D.new()
			tile.texture = tileTexture
			tile.centered = false
			tile.position = Vector2(x, y)
			tile.modulate.a = alpha
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(tile)


func clearTiles() -> void:
	for child in get_children():
		child.queue_free()


func refreshTiles() -> void:
	buildTiles()
