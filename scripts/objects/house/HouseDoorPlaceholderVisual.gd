extends Node2D
class_name HouseDoorPlaceholderVisual

func _ready() -> void:
	z_index = 45
	queue_redraw()


func _draw() -> void:
	var doorRect := Rect2(Vector2(-28, 36), Vector2(56, 64))
	var doorColor := Color(0.26, 0.15, 0.08, 1.0)
	var outline := Color(0.12, 0.07, 0.04, 1.0)
	
	draw_rect(doorRect, doorColor, true)
	draw_rect(doorRect, outline, false, 2.0)
	draw_circle(Vector2(18, 68), 2.5, Color(0.75, 0.55, 0.25, 1.0))
