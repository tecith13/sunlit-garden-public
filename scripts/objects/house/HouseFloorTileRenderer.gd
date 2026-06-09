extends Node2D
class_name HouseFloorTileRenderer

@export var renderEnabled: bool = true
@export var tileTexture: Texture2D
@export var tileSize: int = 32

@export var floorSize: Vector2i = Vector2i(256, 160)
@export var floorTopLeft: Vector2 = Vector2(-128, -52)

@export var zIndexValue: int = -20
@export var alpha: float = 1.0


func _ready() -> void:
	z_index = zIndexValue
	call_deferred("buildFloorTiles")


func buildFloorTiles() -> void:
	clearTiles()
	
	if not renderEnabled:
		return
	
	if tileTexture == null:
		push_warning("HouseFloorTileRenderer: tileTexture is null.")
		return
	
	var columns: int = int(ceil(float(floorSize.x) / float(tileSize)))
	var rows: int = int(ceil(float(floorSize.y) / float(tileSize)))
	
	for y in range(rows):
		for x in range(columns):
			var tile := Sprite2D.new()
			tile.texture = tileTexture
			tile.centered = false
			tile.position = floorTopLeft + Vector2(x * tileSize, y * tileSize)
			tile.modulate.a = alpha
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(tile)


func clearTiles() -> void:
	for child in get_children():
		child.queue_free()


func refreshTiles() -> void:
	buildFloorTiles()
