extends Node2D
class_name HouseWallTileRenderer

enum WallDirection {
	HORIZONTAL,
	VERTICAL
}

@export var renderEnabled: bool = true
@export var wallTexture: Texture2D

@export var tileSize: Vector2i = Vector2i(32, 96)
@export var tileCount: int = 8
@export var direction: WallDirection = WallDirection.HORIZONTAL

# HORIZONTAL 기준:
# startPosition = 첫 타일의 좌상단
#
# VERTICAL 기준:
# startPosition = 첫 타일의 좌상단
@export var startPosition: Vector2 = Vector2.ZERO

@export var zIndexValue: int = -9
@export var alpha: float = 1.0

@export var rotateVerticalTiles: bool = false


func _ready() -> void:
	z_index = zIndexValue
	call_deferred("buildWallTiles")


func buildWallTiles() -> void:
	clearTiles()
	
	if not renderEnabled:
		return
	
	if wallTexture == null:
		push_warning("HouseWallTileRenderer: wallTexture is null.")
		return
	
	for i in range(tileCount):
		var tile := Sprite2D.new()
		tile.texture = wallTexture
		tile.centered = false
		tile.modulate.a = alpha
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		match direction:
			WallDirection.HORIZONTAL:
				tile.position = startPosition + Vector2(i * tileSize.x, 0)
			
			WallDirection.VERTICAL:
				tile.position = startPosition + Vector2(0, i * tileSize.x)
				
				if rotateVerticalTiles:
					tile.rotation_degrees = 90.0
		
		add_child(tile)


func clearTiles() -> void:
	for child in get_children():
		child.queue_free()


func refreshTiles() -> void:
	buildWallTiles()
