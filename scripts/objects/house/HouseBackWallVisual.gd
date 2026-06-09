extends Node2D
class_name HouseBackWallVisual

@export var zIndexValue: int = -10

func _ready() -> void:
	z_index = zIndexValue
	queue_redraw()


func _draw() -> void:
	var wallColor := Color(0.74, 0.63, 0.48, 0.95)
	var wallDark := Color(0.34, 0.24, 0.16, 0.75)
	var wallLine := Color(0.42, 0.30, 0.20, 0.35)
	
	var backWallRect := Rect2(Vector2(-120, -132), Vector2(240, 42))
	var leftWallRect := Rect2(Vector2(-128, -132), Vector2(18, 160))
	var rightWallRect := Rect2(Vector2(110, -132), Vector2(18, 160))
	
	draw_rect(backWallRect, wallColor, true)
	draw_rect(leftWallRect, wallColor, true)
	draw_rect(rightWallRect, wallColor, true)
	
	draw_rect(backWallRect, wallDark, false, 2.0)
	draw_rect(leftWallRect, wallDark, false, 2.0)
	draw_rect(rightWallRect, wallDark, false, 2.0)
	
	for x in range(-96, 97, 32):
		draw_line(
			Vector2(x, backWallRect.position.y + 4),
			Vector2(x, backWallRect.position.y + backWallRect.size.y - 4),
			wallLine,
			1.0
		)
