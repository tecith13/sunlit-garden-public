extends Node2D

@export var interactDistance: float = 80.0
@export var debugLog: bool = false

@export var normalFrontWallAlpha: float = 1.0
@export var occludedFrontWallAlpha: float = 0.35
@export var frontWallRootPath: NodePath = NodePath("FrontWallRoot")

@onready var interactionPoint: Marker2D = $InteractionPoint
@onready var frontOcclusionArea: Area2D = $FrontOcclusionArea
@onready var frontWallRoot: CanvasItem = get_node_or_null(frontWallRootPath) as CanvasItem

var player: Node2D = null
var gameManager: Node = null
var playerInsideFrontOcclusion: bool = false


func _ready() -> void:
	#add_to_group("house")
	add_to_group("interactable")
	add_to_group("player_house")

	refreshReferences()
	connectFrontOcclusionArea()
	setFrontWallAlpha(normalFrontWallAlpha)

	if debugLog:
		print("House ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		trySleep()


func refreshReferences() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if gameManager == null:
		gameManager = get_tree().get_first_node_in_group("game_manager")


func connectFrontOcclusionArea() -> void:
	if frontOcclusionArea == null:
		if debugLog:
			print("House: FrontOcclusionArea not found.")
		return

	if not frontOcclusionArea.body_entered.is_connected(_on_front_occlusion_area_body_entered):
		frontOcclusionArea.body_entered.connect(_on_front_occlusion_area_body_entered)

	if not frontOcclusionArea.body_exited.is_connected(_on_front_occlusion_area_body_exited):
		frontOcclusionArea.body_exited.connect(_on_front_occlusion_area_body_exited)


func _on_front_occlusion_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	playerInsideFrontOcclusion = true
	setFrontWallAlpha(occludedFrontWallAlpha)


func _on_front_occlusion_area_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	playerInsideFrontOcclusion = false
	setFrontWallAlpha(normalFrontWallAlpha)


func setFrontWallAlpha(alpha: float) -> void:
	if frontWallRoot == null:
		if debugLog:
			print("House: FrontWallRoot not found.")
		return

	var color := frontWallRoot.modulate
	color.a = alpha
	frontWallRoot.modulate = color


func trySleep() -> void:
	refreshReferences()

	if player == null:
		if debugLog:
			print("House: Player not found.")
		return

	if gameManager == null:
		if debugLog:
			print("House: GameManager not found.")
		return

	var distance := interactionPoint.global_position.distance_to(player.global_position)

	if distance > interactDistance:
		if debugLog:
			print("Too far from house. Distance: ", distance)
		return

	sleep()


func sleep() -> void:
	if debugLog:
		print("Sleep at house.")

	if gameManager.has_method("nextDay"):
		gameManager.nextDay()
	elif gameManager.has_method("goToNextDay"):
		gameManager.goToNextDay()

	if "currentDay" in gameManager:
		showLocalizedFeedbackText("feedback.next_day", [gameManager.currentDay])


func showLocalizedFeedbackText(key: String, values: Array = []) -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("showLocalizedFeedbackText"):
		uiManager.showLocalizedFeedbackText(key, values)
