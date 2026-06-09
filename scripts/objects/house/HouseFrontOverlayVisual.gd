extends Node2D
class_name HouseFrontOverlayVisual

@export var zIndexValue: int = 40
@export var visibleWhenInside: bool = true

func _ready() -> void:
	z_index = zIndexValue
	queue_redraw()


func _draw() -> void:
	var wallColor := Color(0.74, 0.63, 0.48, 0.95)
	var wallDark := Color(0.34, 0.24, 0.16, 0.85)
	var doorColor := Color(0.28, 0.18, 0.11, 0.95)
	
	var frontWallLeft := Rect2(Vector2(-120, 28), Vector2(78, 40))
	var frontWallRight := Rect2(Vector2(42, 28), Vector2(78, 40))
	var doorRect := Rect2(Vector2(-28, 26), Vector2(56, 46))
	
	draw_rect(frontWallLeft, wallColor, true)
	draw_rect(frontWallRight, wallColor, true)
	draw_rect(frontWallLeft, wallDark, false, 2.0)
	draw_rect(frontWallRight, wallDark, false, 2.0)
	
	draw_rect(doorRect, doorColor, true)
	draw_rect(doorRect, wallDark, false, 2.0)
	draw_circle(Vector2(18, 50), 2.5, Color(0.75, 0.55, 0.25, 0.9))
