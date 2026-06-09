extends Node2D
class_name HouseRoofPrototypeVisual


func _ready() -> void:
	print("RoofVisual ready")
	queue_redraw()


func _draw() -> void:
	drawRoof()


func drawRoof() -> void:
	var roofColor := Color(0.35, 0.23, 0.15, 1.0)
	var roofDark := Color(0.16, 0.10, 0.07, 1.0)
	var roofLight := Color(0.56, 0.38, 0.22, 0.75)
	
	var roofPoly := PackedVector2Array([
		Vector2(-146, -96),
		Vector2(0, -184),
		Vector2(146, -96),
		Vector2(116, -46),
		Vector2(-116, -46)
	])
	
	draw_polygon(roofPoly, PackedColorArray([roofColor]))
	draw_polyline(roofPoly, roofDark, 3.0, true)
	
	# roof tile lines
	for i in range(6):
		var y: float = lerp(-88.0, -54.0, float(i) / 5.0)
		draw_line(Vector2(-110, y), Vector2(110, y), roofDark, 1.0)

	draw_line(Vector2(-66, -106), Vector2(0, -150), roofLight, 2.0)
	draw_line(Vector2(0, -150), Vector2(70, -106), roofLight, 2.0)
