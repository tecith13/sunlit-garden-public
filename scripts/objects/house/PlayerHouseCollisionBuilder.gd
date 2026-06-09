extends Node2D
class_name PlayerHouseCollisionBuilder

@export var buildOnReady: bool = true
@export var debugLog: bool = false

# House visual 기준값.
@export var leftX: float = -128.0
@export var rightX: float = 128.0

@export var wallTopY: float = -148.0
@export var seamY: float = -52.0
@export var floorBottomY: float = 128.0

# 문 통과 영역.
@export var doorWidth: float = 56.0
@export var frontCollisionHeight: float = 22.0

# 충돌 두께.
@export var backWallThickness: float = 22.0
@export var sideWallThickness: float = 18.0

@export var wallCollisionPath: NodePath = NodePath("WallCollision")


func _ready() -> void:
	if buildOnReady:
		buildCollisions()


func buildCollisions() -> void:
	var wallCollision := get_node_or_null(wallCollisionPath) as StaticBody2D
	
	if wallCollision == null:
		push_warning("PlayerHouseCollisionBuilder: WallCollision not found.")
		return
	
	setupRectangleCollision(
		wallCollision,
		"BackWallCollision",
		Vector2(rightX - leftX, backWallThickness),
		Vector2((leftX + rightX) * 0.5, wallTopY + backWallThickness * 0.5)
	)
	
	setupRectangleCollision(
		wallCollision,
		"LeftWallCollision",
		Vector2(sideWallThickness, floorBottomY - wallTopY),
		Vector2(leftX + sideWallThickness * 0.5, (wallTopY + floorBottomY) * 0.5)
	)
	
	setupRectangleCollision(
		wallCollision,
		"RightWallCollision",
		Vector2(sideWallThickness, floorBottomY - wallTopY),
		Vector2(rightX - sideWallThickness * 0.5, (wallTopY + floorBottomY) * 0.5)
	)
	
	var doorHalfWidth: float = doorWidth * 0.5
	var frontY: float = floorBottomY - frontCollisionHeight * 0.5
	
	# 앞벽 왼쪽: leftX ~ -doorHalfWidth
	var frontLeftWidth: float = max(0.0, -doorHalfWidth - leftX)
	setupRectangleCollision(
		wallCollision,
		"FrontLeftCollision",
		Vector2(frontLeftWidth, frontCollisionHeight),
		Vector2(leftX + frontLeftWidth * 0.5, frontY)
	)
	
	# 앞벽 오른쪽: doorHalfWidth ~ rightX
	var frontRightWidth: float = max(0.0, rightX - doorHalfWidth)
	setupRectangleCollision(
		wallCollision,
		"FrontRightCollision",
		Vector2(frontRightWidth, frontCollisionHeight),
		Vector2(doorHalfWidth + frontRightWidth * 0.5, frontY)
	)
	
	if debugLog:
		print("PlayerHouseCollisionBuilder built collisions.")
		print("- wallTopY: ", wallTopY, " seamY: ", seamY, " floorBottomY: ", floorBottomY)
		print("- leftX: ", leftX, " rightX: ", rightX, " doorWidth: ", doorWidth)


func setupRectangleCollision(parent: Node, shapeName: String, size: Vector2, position: Vector2) -> void:
	var collisionShape := parent.get_node_or_null(shapeName) as CollisionShape2D
	
	if collisionShape == null:
		collisionShape = CollisionShape2D.new()
		collisionShape.name = shapeName
		parent.add_child(collisionShape)
	
	var rectangle := collisionShape.shape as RectangleShape2D
	
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		collisionShape.shape = rectangle
	
	rectangle.size = size
	collisionShape.position = position
	collisionShape.disabled = false
	
	if debugLog:
		print(shapeName, " size:", size, " position:", position)
