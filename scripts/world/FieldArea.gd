extends Node2D

@export var debugLog: bool = true


# 밭 기본 설정
@export var cellSize: int = 32
@export var gridWidth: int = 35
@export var gridHeight: int = 22
@export var useFarmBlockerCellRectCheck: bool = false

# 도구를 사용할 수 있는 최대 거리.
@export var maxToolDistance: float = 48.0

# 현재 기본 작물
@export var defaultCropId: String = "carrot"

# 마른 풀
@onready var dryDirtPatchCells: Node2D = $DryDirtPatchCells

# 밭 타일 이미지
@export var tilledSoilTexture: Texture2D = preload("res://assets/sprites/tiles/soil/soil_tilled.png")
@export var wateredSoilTexture: Texture2D = preload("res://assets/sprites/tiles/soil/soil_watered.png")

# 시각 노드
@onready var scratchCells: Node2D = $ScratchCells
@onready var partlyTilledCells: Node2D = $PartlyTilledCells
@onready var tilledCells: Node2D = $TilledCells
@onready var wateredCells: Node2D = $WateredCells
#@onready var cropCells: Node2D = $CropCells
@export var cropCellsPath: NodePath
@onready var cropCells: Node2D = get_node(cropCellsPath)


const DRY_DIRT_PATCH_01 := preload("res://assets/sprites/ground/dry_dirt/dry_dirt_patch_01.png")
const DRY_DIRT_PATCH_02 := preload("res://assets/sprites/ground/dry_dirt/dry_dirt_patch_02.png")
const DRY_DIRT_PATCH_03 := preload("res://assets/sprites/ground/dry_dirt/dry_dirt_patch_03.png")
const DRY_DIRT_PATCH_04 := preload("res://assets/sprites/ground/dry_dirt/dry_dirt_patch_04.png")

# Tilled sprite names are based on the visual open/end direction,
# not the connected neighbor direction.
# Example:
# if the current cell connects to the UP neighbor,
# use TILLED_END_DOWN because the visible end is on the opposite side.
const TILLED_SINGLE := preload("res://assets/sprites/ground/tilled/hoe_tilled_single.png")
const TILLED_LINE_H := preload("res://assets/sprites/ground/tilled/hoe_tilled_line_h.png")
const TILLED_LINE_V := preload("res://assets/sprites/ground/tilled/hoe_tilled_line_v.png")

# NOTE:
# Corner sprite names are based on the visually open/remaining edge direction,
# not the connected neighbor directions.
const TILLED_CORNER_UP_RIGHT := preload("res://assets/sprites/ground/tilled/hoe_tilled_corner_up_right.png")
const TILLED_CORNER_DOWN_RIGHT := preload("res://assets/sprites/ground/tilled/hoe_tilled_corner_down_right.png")
const TILLED_CORNER_DOWN_LEFT := preload("res://assets/sprites/ground/tilled/hoe_tilled_corner_down_left.png")
const TILLED_CORNER_UP_LEFT := preload("res://assets/sprites/ground/tilled/hoe_tilled_corner_up_left.png")

const TILLED_T_UP := preload("res://assets/sprites/ground/tilled/hoe_tilled_t_up.png")
const TILLED_T_RIGHT := preload("res://assets/sprites/ground/tilled/hoe_tilled_t_right.png")
const TILLED_T_DOWN := preload("res://assets/sprites/ground/tilled/hoe_tilled_t_down.png")
const TILLED_T_LEFT := preload("res://assets/sprites/ground/tilled/hoe_tilled_t_left.png")

const TILLED_CROSS := preload("res://assets/sprites/ground/tilled/hoe_tilled_cross.png")
const TILLED_CENTER := preload("res://assets/sprites/ground/tilled/hoe_tilled_center.png")

# NOTE:
# TILLED_END_UP means the tile visually ends/open-space is on the up side,
# NOT that it connects to the up neighbor.
#
# So if the current cell connects to the up neighbor,
# we must use TILLED_END_DOWN.
const TILLED_END_UP := preload("res://assets/sprites/ground/tilled/hoe_tilled_end_up.png")
const TILLED_END_RIGHT := preload("res://assets/sprites/ground/tilled/hoe_tilled_end_right.png")
const TILLED_END_DOWN := preload("res://assets/sprites/ground/tilled/hoe_tilled_end_down.png")
const TILLED_END_LEFT := preload("res://assets/sprites/ground/tilled/hoe_tilled_end_left.png")

const SCRATCH_01 := preload("res://assets/sprites/ground/scratch/hoe_scratch_01.png")
const SCRATCH_02 := preload("res://assets/sprites/ground/scratch/hoe_scratch_02.png")
const SCRATCH_03 := preload("res://assets/sprites/ground/scratch/hoe_scratch_03.png")

const PARTLY_TILLED_01 := preload("res://assets/sprites/ground/tilled/hoe_partly_tilled_01.png")
const PARTLY_TILLED_02 := preload("res://assets/sprites/ground/tilled/hoe_partly_tilled_02.png")
const PARTLY_TILLED_03 := preload("res://assets/sprites/ground/tilled/hoe_partly_tilled_03.png")

const WATERED_SINGLE := preload("res://assets/sprites/ground/watered/hoe_watered_single.png")
const WATERED_CENTER := preload("res://assets/sprites/ground/watered/hoe_watered_center.png")

const WATERED_END_UP := preload("res://assets/sprites/ground/watered/hoe_watered_end_up.png")
const WATERED_END_RIGHT := preload("res://assets/sprites/ground/watered/hoe_watered_end_right.png")
const WATERED_END_DOWN := preload("res://assets/sprites/ground/watered/hoe_watered_end_down.png")
const WATERED_END_LEFT := preload("res://assets/sprites/ground/watered/hoe_watered_end_left.png")

const WATERED_LINE_H := preload("res://assets/sprites/ground/watered/hoe_watered_line_h.png")
const WATERED_LINE_V := preload("res://assets/sprites/ground/watered/hoe_watered_line_v.png")

const WATERED_CORNER_UP_RIGHT := preload("res://assets/sprites/ground/watered/hoe_watered_corner_up_right.png")
const WATERED_CORNER_DOWN_RIGHT := preload("res://assets/sprites/ground/watered/hoe_watered_corner_down_right.png")
const WATERED_CORNER_DOWN_LEFT := preload("res://assets/sprites/ground/watered/hoe_watered_corner_down_left.png")
const WATERED_CORNER_UP_LEFT := preload("res://assets/sprites/ground/watered/hoe_watered_corner_up_left.png")

const WATERED_T_UP := preload("res://assets/sprites/ground/watered/hoe_watered_t_up.png")
const WATERED_T_RIGHT := preload("res://assets/sprites/ground/watered/hoe_watered_t_right.png")
const WATERED_T_DOWN := preload("res://assets/sprites/ground/watered/hoe_watered_t_down.png")
const WATERED_T_LEFT := preload("res://assets/sprites/ground/watered/hoe_watered_t_left.png")


# 외부 매니저 / 노드 참조
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
var toolManager: Node = null
var inventoryManager: Node = null
var cropDatabase: Node = null

# 밭의 각 칸 상태를 저장하는 Dictionary.
var fieldData: Dictionary = {}
const HOE_STAGE_NONE := 0
const HOE_STAGE_SCRATCH := 1
const HOE_STAGE_PARTLY_TILLED := 2
const HOE_STAGE_TILLED := 3

# 시각 노드 추적
var cropVisuals: Dictionary = {}
var wateredVisuals: Dictionary = {}
var printedFarmBlockerDebugSummary: bool = false

# dry_grass patch
#@export var clearableObjectsRootPath: NodePath
#@export var deadGrassPatchScene: PackedScene
#@export_range(0, 100) var deadGrassSpawnChance: int = 40
#
#@onready var clearableObjectsRoot: Node2D = get_node_or_null(clearableObjectsRootPath) as Node2D




func _ready() -> void:
	add_to_group("field_area")
	initializeFieldData()
	syncFieldDebugAreaSize()
	refreshReferences()
	#generateInitialDeadGrassPatches()
	debugPrintFarmBlockers("FieldArea ready")
	if debugLog:
		print("FieldArea script connected")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		handleUseTool()
			

func refreshReferences() -> void:
	if toolManager == null:
		toolManager = get_tree().get_first_node_in_group("tool_manager")

	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if cropDatabase == null:
		cropDatabase = get_tree().get_first_node_in_group("crop_database")

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D


func handleUseTool() -> void:
	if get_viewport().is_input_handled():
		return

	refreshReferences()

	if toolManager == null:
		if debugLog:
			print("ToolManager not found.")
		return

	var mouseWorldPosition := get_global_mouse_position()
	var cellPosition := worldToCell(mouseWorldPosition)

	# 밭 밖 클릭은 정상 상황이므로 조용히 무시.
	if isValidCell(cellPosition) == false:
		return

	if canUseToolAtCell(cellPosition) == false:
		if debugLog:
			print("Too far from cell: ", cellPosition)
		return

	if toolManager.isHoeSelected():
		requestHoeCell(cellPosition)
		return

	if toolManager.isWateringCanSelected():
		waterCell(cellPosition)
		return

	if toolManager.isSeedSelected():
		plantSeed(cellPosition)
		return

	if toolManager.isHandSelected():
		harvestCrop(cellPosition)
		return


func initializeFieldData() -> void:
	fieldData.clear()

	for y in range(gridHeight):
		for x in range(gridWidth):
			var cellPosition := Vector2i(x, y)

			fieldData[cellPosition] = {
				"cleared": false,
				"tilled": false,
				"watered": false,
				"cropId": "",
				"growthStage": -1,
				"hoeStage": 0
			}


func syncFieldDebugAreaSize() -> void:
	var debugArea := get_node_or_null("FieldDebugArea") as ColorRect
	if debugArea == null:
		return

	debugArea.offset_left = 0.0
	debugArea.offset_top = 0.0
	debugArea.offset_right = gridWidth * cellSize
	debugArea.offset_bottom = gridHeight * cellSize


func worldToCell(worldPosition: Vector2) -> Vector2i:
	# 월드 좌표를 FieldArea 기준 로컬 좌표로 변환.
	var localPosition := to_local(worldPosition)

	var cellX := floori(localPosition.x / cellSize)
	var cellY := floori(localPosition.y / cellSize)

	return Vector2i(cellX, cellY)


func cellToWorldCenter(cellPosition: Vector2i) -> Vector2:
	# 셀 중심점을 월드 좌표로 변환.
	var localCenter := Vector2(
		cellPosition.x * cellSize + cellSize / 2.0,
		cellPosition.y * cellSize + cellSize / 2.0
	)

	return to_global(localCenter)


func isValidCell(cellPosition: Vector2i) -> bool:
	if cellPosition.x < 0:
		return false

	if cellPosition.y < 0:
		return false

	if cellPosition.x >= gridWidth:
		return false

	if cellPosition.y >= gridHeight:
		return false

	return true


func canUseToolAtCell(cellPosition: Vector2i) -> bool:
	if player == null:
		if debugLog:
			print("Player not found. Add Player node to 'player' group.")
		return false

	var cellWorldCenter := cellToWorldCenter(cellPosition)
	var distanceToCell := player.global_position.distance_to(cellWorldCenter)

	return distanceToCell <= maxToolDistance


func canTillCell(cellPosition: Vector2i) -> bool:
	if isValidCell(cellPosition) == false:
		return false

	if fieldData.has(cellPosition) == false:
		if debugLog:
			print("Cannot till missing fieldData cell: ", cellPosition)
		return false

	if canUseToolAtCell(cellPosition) == false:
		if debugLog:
			print("Cannot till too far from cell: ", cellPosition)
		return false

	var cellData: Dictionary = fieldData[cellPosition]

	if String(cellData.get("cropId", "")) != "":
		if debugLog:
			print("Cannot till cell with crop: ", cellPosition, " cropId: ", cellData.get("cropId", ""))
		return false

	if bool(cellData.get("tilled", false)):
		if debugLog:
			print("Cannot till already tilled cell: ", cellPosition)
		return false

	if isCellFarmBlocked(cellPosition):
		if debugLog:
			print("Cannot till blocked cell: ", cellPosition)
		return false

	return true


func requestHoeCell(cellPosition: Vector2i) -> void:
	if canTillCell(cellPosition) == false:
		return

	refreshReferences()

	if player != null and player.has_method("startHoeAction"):
		player.call("startHoeAction", Callable(self, "tillCell").bind(cellPosition))
		return

	tillCell(cellPosition)


func debugPrintFarmBlockers(context: String) -> void:
	if debugLog == false:
		return

	if printedFarmBlockerDebugSummary and context != "tillCell":
		return

	var blockers := get_tree().get_nodes_in_group("no_farm_blocker")
	var blockerNames: Array[String] = []

	for blocker in blockers:
		if blocker is Node:
			blockerNames.append((blocker as Node).name)
		else:
			blockerNames.append(str(blocker))

	print(
		"Farm blocker debug [",
		context,
		"] count: ",
		blockers.size(),
		" names: ",
		blockerNames
	)

	printedFarmBlockerDebugSummary = true


func isCellFarmBlocked(cellPosition: Vector2i) -> bool:
	var center := cellToWorldCenter(cellPosition)
	var pointsToCheck: Array[Vector2] = [center]

	if useFarmBlockerCellRectCheck:
		var cellRect := getCellWorldRect(cellPosition)
		pointsToCheck.append(cellRect.position)
		pointsToCheck.append(cellRect.position + Vector2(cellRect.size.x, 0.0))
		pointsToCheck.append(cellRect.position + Vector2(0.0, cellRect.size.y))
		pointsToCheck.append(cellRect.position + cellRect.size)

	var blockers := get_tree().get_nodes_in_group("no_farm_blocker")
	if debugLog:
		print(
			"isCellFarmBlocked cellPosition: ",
			cellPosition,
			" center: ",
			center,
			" no_farm_blocker count: ",
			blockers.size()
		)

	for blocker in blockers:
		if blocker is Area2D == false:
			if debugLog:
				print("Skipping non-Area2D no_farm_blocker: ", blocker)
			continue

		var blockerArea := blocker as Area2D
		if debugLog:
			print("Checking farm blocker: ", blockerArea.name, " global_position: ", blockerArea.global_position)

		for point in pointsToCheck:
			if farmBlockerContainsWorldPoint(blockerArea, point):
				if debugLog:
					print("Field cell blocked by no_farm_blocker: ", cellPosition, " blocker: ", blockerArea.name)
				return true

	if debugLog:
		print("Field cell is not blocked: ", cellPosition)

	return false


func farmBlockerContainsWorldPoint(blockerArea: Area2D, worldPoint: Vector2) -> bool:
	var containsPoint := false

	for child in blockerArea.get_children():
		if child is CollisionShape2D == false:
			continue

		var collisionShape := child as CollisionShape2D
		if debugLog:
			print(
				"  Shape: ",
				collisionShape.name,
				" disabled: ",
				collisionShape.disabled,
				" global_position: ",
				collisionShape.global_position,
				" shape: ",
				collisionShape.shape
			)

		if collisionShape.disabled or collisionShape.shape == null:
			continue

		var shapeContainsPoint := shapeContainsWorldPoint(collisionShape, worldPoint)
		if debugLog:
			print("  point: ", worldPoint, " contained: ", shapeContainsPoint)

		if shapeContainsPoint:
			containsPoint = true
			break

	return containsPoint


func shapeContainsWorldPoint(collisionShape: CollisionShape2D, worldPoint: Vector2) -> bool:
	var localPoint := collisionShape.global_transform.affine_inverse() * worldPoint
	var shape := collisionShape.shape

	if shape is RectangleShape2D:
		var rectangle := shape as RectangleShape2D
		var halfSize := rectangle.size * 0.5
		var result := absf(localPoint.x) <= halfSize.x and absf(localPoint.y) <= halfSize.y
		if debugLog:
			print(
				"    RectangleShape2D size: ",
				rectangle.size,
				" halfSize: ",
				halfSize,
				" localPoint: ",
				localPoint,
				" result: ",
				result
			)
		return result

	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		var result := localPoint.length() <= circle.radius
		if debugLog:
			print(
				"    CircleShape2D radius: ",
				circle.radius,
				" localPoint: ",
				localPoint,
				" result: ",
				result
			)
		return result

	if debugLog:
		print("    Unsupported farm blocker shape type: ", shape, " localPoint: ", localPoint)

	return false


func tillCell(cellPosition: Vector2i) -> void:
	if isValidCell(cellPosition) == false:
		return

	if fieldData.has(cellPosition) == false:
		return

	var cellData: Dictionary = fieldData[cellPosition]
	var currentStage: int = int(cellData.get("hoeStage", HOE_STAGE_NONE))

	if debugLog:
		debugPrintFarmBlockers("tillCell")
		print(
			"tillCell called cellPosition: ",
			cellPosition,
			" center: ",
			cellToWorldCenter(cellPosition),
			" hoeStage: ",
			currentStage,
			" tilled: ",
			cellData["tilled"]
		)

	if cellData["tilled"] == true:
		if debugLog:
			print("tillCell returning: already tilled at ", cellPosition)
		return

	if String(cellData.get("cropId", "")) != "":
		if debugLog:
			print("tillCell returning: crop exists at ", cellPosition, " cropId: ", cellData.get("cropId", ""))
		return

	if isCellFarmBlocked(cellPosition):
		if debugLog:
			print("tillCell returning: blocked by no_farm_blocker at ", cellPosition)
		return

	var nextStage: int = min(currentStage + 1, HOE_STAGE_TILLED)

	cellData["hoeStage"] = nextStage

	if nextStage == HOE_STAGE_SCRATCH:
		refreshScratchCellVisual(cellPosition)

	elif nextStage == HOE_STAGE_PARTLY_TILLED:
		removeScratchCellVisual(cellPosition)
		refreshPartlyTilledCellVisual(cellPosition)

	elif nextStage == HOE_STAGE_TILLED:
		removeScratchCellVisual(cellPosition)
		removePartlyTilledCellVisual(cellPosition)

		cellData["tilled"] = true
		refreshTilledCellAndNeighbors(cellPosition)
		finalizeFarmCell(cellPosition)

	if debugLog:
		print("Hoe stage ", nextStage, " at: ", cellPosition)


func tryConvertRecoveredSoilAtWorldPosition(worldPosition: Vector2) -> bool:
	var cellPosition := worldToCell(worldPosition)
	var validCell := isValidCell(cellPosition)

	if debugLog:
		print(
			"tryConvertRecoveredSoilAtWorldPosition worldPosition: ",
			worldPosition,
			" cellPosition: ",
			cellPosition,
			" isValidCell: ",
			validCell
		)

	if validCell == false:
		if debugLog:
			print("tryConvertRecoveredSoilAtWorldPosition failed: invalid FieldArea cell.")
		return false

	var farmBlocked := isCellFarmBlocked(cellPosition)
	if debugLog:
		print("tryConvertRecoveredSoilAtWorldPosition farmBlocked: ", farmBlocked)

	if farmBlocked:
		if debugLog:
			print("tryConvertRecoveredSoilAtWorldPosition failed: no_farm_blocker at cell: ", cellPosition)
		return false

	var cellData: Dictionary = fieldData[cellPosition]

	if String(cellData.get("cropId", "")) != "":
		if debugLog:
			print(
				"tryConvertRecoveredSoilAtWorldPosition failed: crop already exists. cropId: ",
				cellData.get("cropId", "")
			)
		return false

	if bool(cellData.get("tilled", false)):
		if debugLog:
			print("tryConvertRecoveredSoilAtWorldPosition failed: cell already tilled.")
		return false

	cellData["cleared"] = true
	cellData["tilled"] = true
	cellData["watered"] = false
	cellData["hoeStage"] = HOE_STAGE_TILLED

	removeScratchCellVisual(cellPosition)
	removePartlyTilledCellVisual(cellPosition)
	refreshTilledCellAndNeighbors(cellPosition)
	refreshWateredCellAndNeighbors(cellPosition)
	finalizeFarmCell(cellPosition)

	if debugLog:
		print("Converted recovered soil to tilled FieldArea cell: ", cellPosition)

	return true


func canConvertRecoveredSoilAtWorldPosition(worldPosition: Vector2) -> bool:
	var cellPosition := worldToCell(worldPosition)

	if debugLog:
		print(
			"canConvertRecoveredSoilAtWorldPosition worldPosition: ",
			worldPosition,
			" cellPosition: ",
			cellPosition
		)

	if isValidCell(cellPosition) == false:
		if debugLog:
			print("Cannot convert recovered soil: invalid FieldArea cell: ", cellPosition)
		return false

	if fieldData.has(cellPosition) == false:
		if debugLog:
			print("Cannot convert recovered soil: missing fieldData cell: ", cellPosition)
		return false

	if isCellFarmBlocked(cellPosition):
		if debugLog:
			print("Cannot convert recovered soil: no_farm_blocker at cell: ", cellPosition)
		return false

	var cellData: Dictionary = fieldData[cellPosition]

	if debugLog:
		print(
			"  canConvert cellData tilled: ",
			cellData.get("tilled", false),
			" hoeStage: ",
			cellData.get("hoeStage", HOE_STAGE_NONE),
			" watered: ",
			cellData.get("watered", false),
			" cropId: ",
			cellData.get("cropId", "")
		)

	if String(cellData.get("cropId", "")) != "":
		if debugLog:
			print("Cannot convert recovered soil: crop already exists at ", cellPosition)
		return false

	if bool(cellData.get("tilled", false)):
		if debugLog:
			print("Cannot convert recovered soil: cell already tilled: ", cellPosition)
		return false

	if debugLog:
		print("Can convert recovered soil at cell: ", cellPosition)

	return true


func isWorldPositionFarmBlocked(worldPosition: Vector2) -> bool:
	var cellPosition := worldToCell(worldPosition)

	if isValidCell(cellPosition) == false:
		return false

	return isCellFarmBlocked(cellPosition)


func isWorldPositionOnTilledOrCropCell(worldPosition: Vector2) -> bool:
	var cellPosition := worldToCell(worldPosition)

	if isValidCell(cellPosition) == false:
		return false

	if fieldData.has(cellPosition) == false:
		return false

	var cellData: Dictionary = fieldData[cellPosition]
	return bool(cellData.get("tilled", false)) or String(cellData.get("cropId", "")) != ""


func getCellWorldRect(cellPosition: Vector2i) -> Rect2:
	var localTopLeft := Vector2(
		cellPosition.x * cellSize,
		cellPosition.y * cellSize
	)
	var worldTopLeft := to_global(localTopLeft)
	return Rect2(worldTopLeft, Vector2(cellSize, cellSize))


func finalizeFarmCell(cellPosition: Vector2i) -> void:
	clearFarmVegetationAtCell(cellPosition)
	convertDeadGrassSoilPatchesAtCell(cellPosition)

	if debugLog:
		print("Finalized farm cell: ", cellPosition)


func convertDeadGrassSoilPatchesAtCell(cellPosition: Vector2i) -> void:
	var convertedCount := 0
	var soilPatches := get_tree().get_nodes_in_group("waterable_soil_patch")

	for object in soilPatches:
		if object == null:
			continue

		if object.has_method("getSoilPatchWorldPosition") == false:
			continue

		if object.has_method("isCleared") == false:
			continue

		if bool(object.call("isCleared")) == false:
			continue

		if object.has_method("getSoilState") == false:
			continue

		var objectSoilState: String = str(object.call("getSoilState"))

		if objectSoilState == "converted":
			continue

		if objectSoilState != "dry" and objectSoilState != "watered" and objectSoilState != "recovered":
			continue

		var objectSoilPosition: Vector2 = object.call("getSoilPatchWorldPosition")
		var objectCell: Vector2i = worldToCell(objectSoilPosition)

		if objectCell != cellPosition:
			continue

		if object.has_method("setSoilState"):
			object.call("setSoilState", "converted")
			convertedCount += 1

	if debugLog and convertedCount > 0:
		print("Converted DeadGrass soil patches at farm cell: ", cellPosition, " count: ", convertedCount)


func clearFarmVegetationAtCell(cellPosition: Vector2i) -> void:
	var cellRect := getCellWorldRect(cellPosition).grow(4.0)
	var clearedCount := 0
	var farmVegetation := get_tree().get_nodes_in_group("farm_clearable_vegetation")

	for object in farmVegetation:
		if object is Node2D == false:
			continue

		var objectNode := object as Node2D

		if cellRect.has_point(objectNode.global_position) == false:
			continue

		objectNode.queue_free()
		clearedCount += 1

	if debugLog and clearedCount > 0:
		print("Cleared farm overlay vegetation at cell: ", cellPosition, " count: ", clearedCount)


func refreshScratchCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "Scratch_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := scratchCells.get_node_or_null(nodeName)

	if existing == null:
		var sprite := Sprite2D.new()
		sprite.name = nodeName
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = getCellLocalCenter(cellPosition)
		scratchCells.add_child(sprite)
		existing = sprite

	existing.texture = getScratchTextureForCell(cellPosition)


func removeScratchCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "Scratch_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := scratchCells.get_node_or_null(nodeName)

	if existing != null:
		existing.queue_free()


func refreshPartlyTilledCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "PartlyTilled_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := partlyTilledCells.get_node_or_null(nodeName)

	if existing == null:
		var sprite := Sprite2D.new()
		sprite.name = nodeName
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = getCellLocalCenter(cellPosition)
		partlyTilledCells.add_child(sprite)
		existing = sprite

	existing.texture = getPartlyTilledTextureForCell(cellPosition)


func removePartlyTilledCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "PartlyTilled_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := partlyTilledCells.get_node_or_null(nodeName)

	if existing != null:
		existing.queue_free()


func getCellLocalCenter(cellPosition: Vector2i) -> Vector2:
	return Vector2(
		cellPosition.x * cellSize + cellSize / 2.0,
		cellPosition.y * cellSize + cellSize / 2.0
	)


func waterCell(cellPosition: Vector2i) -> void:
	# 갈리지 않은 밭에는 물을 줄 수 없음.
	if fieldData[cellPosition]["tilled"] == false:
		if debugLog:
			print("Cannot water untilled cell: ", cellPosition)
		return

	# 이미 물 준 칸이면 중복 생성하지 않음.
	if fieldData[cellPosition]["watered"] == true:
		showLocalizedFeedbackText("feedback.already_watered")
		if debugLog:
			print("Already watered: ", cellPosition)
		return

	fieldData[cellPosition]["watered"] = true
	refreshWateredCellAndNeighbors(cellPosition)
	
	showLocalizedFeedbackText("feedback.watered")

	if debugLog:
		print("Watered Cell: ", cellPosition)


func getWateredTextureForCell(cellPosition: Vector2i) -> Texture2D:
	var up := isCellTilled(cellPosition + Vector2i(0, -1))
	var right := isCellTilled(cellPosition + Vector2i(1, 0))
	var down := isCellTilled(cellPosition + Vector2i(0, 1))
	var left := isCellTilled(cellPosition + Vector2i(-1, 0))

	var count := 0
	if up:
		count += 1
	if right:
		count += 1
	if down:
		count += 1
	if left:
		count += 1

	if count == 0:
		return WATERED_SINGLE

	if count == 1:
		if up:
			return WATERED_END_DOWN
		if right:
			return WATERED_END_LEFT
		if down:
			return WATERED_END_UP
		if left:
			return WATERED_END_RIGHT

	if count == 2:
		if left and right:
			return WATERED_LINE_H
		if up and down:
			return WATERED_LINE_V

		if up and right:
			return WATERED_CORNER_DOWN_LEFT
		if right and down:
			return WATERED_CORNER_UP_LEFT
		if down and left:
			return WATERED_CORNER_UP_RIGHT
		if left and up:
			return WATERED_CORNER_DOWN_RIGHT

	if count == 3:
		if up and right and left:
			return WATERED_T_UP
		if up and right and down:
			return WATERED_T_RIGHT
		if right and down and left:
			return WATERED_T_DOWN
		if down and left and up:
			return WATERED_T_LEFT
	
			
	return WATERED_CENTER


func plantSeed(cellPosition: Vector2i) -> void:
	# InventoryManager를 아직 못 찾았다면 다시 시도.
	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if inventoryManager == null:
		if debugLog:
			print("InventoryManager not found.")
		return

	var seedItemId: String = getSeedItemId(defaultCropId)

	# 갈리지 않은 밭에는 씨앗을 심을 수 없음.
	if fieldData[cellPosition]["tilled"] == false:
		if debugLog:
			print("Cannot plant on untilled cell: ", cellPosition)
		return

	# 이미 작물이 있는 칸에는 다시 심을 수 없음.
	if fieldData[cellPosition]["cropId"] != "":
		if debugLog:
			print("Crop already planted: ", cellPosition)
		return

	# 씨앗이 없으면 심을 수 없음.
	if inventoryManager.hasItem(seedItemId, 1) == false:
		showLocalizedFeedbackText("feedback.not_enough_seed")
		if debugLog:
			print("Not enough seed: ", seedItemId)
		return

	# 씨앗 1개 소비.
	if inventoryManager.removeItem(seedItemId, 1) == false:
		if debugLog:
			print("Failed to consume seed: ", seedItemId)
		return

	# 현재는 테스트용으로 defaultCropId를 심음.
	fieldData[cellPosition]["cropId"] = defaultCropId
	fieldData[cellPosition]["growthStage"] = 0

	var cropVisual := createCropCellVisual(cellPosition, defaultCropId, 0)
	cropCells.add_child(cropVisual)
	cropVisuals[cellPosition] = cropVisual

	var cropDisplayName := getCropDisplayName(defaultCropId)
	showLocalizedFeedbackText("feedback.planted_crop", [cropDisplayName])
	
	if debugLog:
		print("Planted ", defaultCropId, " at: ", cellPosition)
	

func harvestCrop(cellPosition: Vector2i) -> void:
	# InventoryManager를 아직 못 찾았다면 다시 시도.
	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if inventoryManager == null:
		if debugLog:
			print("InventoryManager not found.")
		return

	var cellData: Dictionary = fieldData[cellPosition]

	# 작물이 없는 칸은 수확할 수 없음.
	if cellData["cropId"] == "":
		if debugLog:
			print("No crop to harvest at: ", cellPosition)
		return

	# 성장 단계가 3 미만이면 아직 수확할 수 없음.
	var cropId: String = String(cellData["cropId"])
	var maxStage: int = getMaxGrowthStage(cropId)

	if cellData["growthStage"] < maxStage:
		if debugLog:
			print("Crop is not fully grown at: ", cellPosition, " Stage: ", cellData["growthStage"])
		return

	var harvestedCropId: String = String(cellData["cropId"])

	# 인벤토리에 수확한 작물 추가.
	inventoryManager.addItem(harvestedCropId, 1)
	
	var cropDisplayName := getCropDisplayName(harvestedCropId)
	showLocalizedFeedbackText("feedback.harvested_crop", [cropDisplayName])

	# 작물 시각 노드 제거.
	removeCropVisual(cellPosition)

	# 밭 데이터 초기화.
	# 밭은 갈린 상태로 유지하고, 작물 정보만 제거.
	cellData["cropId"] = ""
	cellData["growthStage"] = -1

	if debugLog:
		print("Harvested ", harvestedCropId, " at: ", cellPosition)

func createTilledCellVisual(cellPosition: Vector2i) -> void:
	#var tilledCell := Sprite2D.new()
#
	#tilledCell.name = "TilledCell_%d_%d" % [cellPosition.x, cellPosition.y]
	#tilledCell.texture = tilledSoilTexture
	##tilledCell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
#
	## Sprite2D는 중심 기준이므로 셀 중앙에 배치.
	#tilledCell.position = Vector2(
		#cellPosition.x * cellSize + cellSize / 2.0,
		#cellPosition.y * cellSize + cellSize / 2.0
	#)

	#tilledCells.add_child(tilledCell)
	
	var sprite := Sprite2D.new()
	sprite.name = "Tilled_%s_%s" % [cellPosition.x, cellPosition.y]
	sprite.texture = getTilledTextureForCell(cellPosition)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = cellToWorldCenter(cellPosition)
	tilledCells.add_child(sprite)

func refreshTilledCellAndNeighbors(cellPosition: Vector2i) -> void:
	refreshTilledCellVisual(cellPosition)
	refreshTilledCellVisual(cellPosition + Vector2i(0, -1))
	refreshTilledCellVisual(cellPosition + Vector2i(1, 0))
	refreshTilledCellVisual(cellPosition + Vector2i(0, 1))
	refreshTilledCellVisual(cellPosition + Vector2i(-1, 0))


func refreshTilledCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "Tilled_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := tilledCells.get_node_or_null(nodeName)
	
	if not isCellTilled(cellPosition):
		if existing != null:
			existing.queue_free()
		return
	
	if existing == null:
		var sprite := Sprite2D.new()
		sprite.name = nodeName
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		#sprite.position = Vector2(
			#cellPosition.x * cellSize + cellSize / 2.0,
			#cellPosition.y * cellSize + cellSize / 2.0
		#)
		sprite.position = getCellLocalCenter(cellPosition)
		tilledCells.add_child(sprite)
		existing = sprite
	
	existing.texture = getTilledTextureForCell(cellPosition)

func getScratchTextureForCell(cellPosition: Vector2i) -> Texture2D:
	var index = abs(int(hash(str(cellPosition)))) % 3

	match index:
		0:
			return SCRATCH_01
		1:
			return SCRATCH_02
		_:
			return SCRATCH_03

func getPartlyTilledTextureForCell(cellPosition: Vector2i) -> Texture2D:
	var index = abs(int(hash(str(cellPosition) + "_partly"))) % 3

	match index:
		0:
			return PARTLY_TILLED_01
		1:
			return PARTLY_TILLED_02
		_:
			return PARTLY_TILLED_03


func createWateredCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "Watered_%s_%s" % [cellPosition.x, cellPosition.y]

	var existing := wateredCells.get_node_or_null(nodeName)

	if existing == null:
		var wateredCell := Sprite2D.new()
		wateredCell.name = nodeName
		wateredCell.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		wateredCell.position = getCellLocalCenter(cellPosition)
		wateredCells.add_child(wateredCell)
		existing = wateredCell

	var wateredSprite := existing as Sprite2D
	wateredSprite.texture = getWateredTextureForCell(cellPosition)

	wateredVisuals[cellPosition] = wateredSprite


func refreshWateredCellVisual(cellPosition: Vector2i) -> void:
	var nodeName := "Watered_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := wateredCells.get_node_or_null(nodeName)

	if fieldData.has(cellPosition) == false:
		if existing != null:
			existing.queue_free()
		return

	var cellData: Dictionary = fieldData[cellPosition]

	if bool(cellData.get("watered", false)) == false:
		if existing != null:
			existing.queue_free()
		wateredVisuals.erase(cellPosition)
		return

	if existing == null:
		var sprite := Sprite2D.new()
		sprite.name = nodeName
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = getCellLocalCenter(cellPosition)
		wateredCells.add_child(sprite)
		existing = sprite

	existing.texture = getWateredTextureForCell(cellPosition)
	wateredVisuals[cellPosition] = existing


func refreshWateredCellAndNeighbors(cellPosition: Vector2i) -> void:
	refreshWateredCellVisual(cellPosition)
	refreshWateredCellVisual(cellPosition + Vector2i(0, -1))
	refreshWateredCellVisual(cellPosition + Vector2i(1, 0))
	refreshWateredCellVisual(cellPosition + Vector2i(0, 1))
	refreshWateredCellVisual(cellPosition + Vector2i(-1, 0))


func createCropCellVisual(cellPosition: Vector2i, cropId: String, growthStage: int) -> Node2D:
	var cropVisual := Node2D.new()
	cropVisual.name = "CropVisual_%d_%d" % [cellPosition.x, cellPosition.y]

	var worldPosition := cellToWorldCenter(cellPosition)
	cropVisual.position = cropCells.to_local(worldPosition)

	if cropDatabase == null:
		refreshReferences()

	if cropDatabase == null:
		if debugLog:
			print("Cannot create crop visual: CropDatabase is null.")
		return cropVisual

	var cropSprite := Sprite2D.new()
	cropSprite.name = "CropSprite"

	var cropTexture: Texture2D = cropDatabase.getCropStageTexture(cropId, growthStage)

	cropSprite.texture = cropTexture
	cropSprite.centered = true
	cropSprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cropSprite.position = Vector2(0, -16)
	cropVisual.add_child(cropSprite)

	return cropVisual


func getCropStageColor(growthStage: int) -> Color:
	match growthStage:
		0:
			# 씨앗
			return Color("#E6A23C")
		1:
			# 새싹
			return Color("#7DBA4D")
		2:
			# 성장 중
			return Color("#4F9A3A")
		3:
			# 완성 당근 임시 색
			return Color("#F28C28")
		_:
			return Color("#FFFFFF")


func getCropVisualSize(growthStage: int) -> Vector2:
	match growthStage:
		0:
			return Vector2(12, 12)
		1:
			return Vector2(14, 14)
		2:
			return Vector2(18, 18)
		3:
			return Vector2(22, 22)
		_:
			return Vector2(12, 12)
			
			
func processNextDay(currentDay: int) -> void:
	if debugLog: 
		print("FieldArea processing day: ", currentDay)

	growCrops()
	clearWateredCells()


func growCrops() -> void:
	for cellPosition in fieldData.keys():
		var cellData: Dictionary = fieldData[cellPosition]

		# 작물이 없는 칸은 무시.
		if cellData["cropId"] == "":
			continue

		# 물을 주지 않은 작물은 성장하지 않음.
		if cellData["watered"] == false:
			continue

		var cropId: String = String(cellData["cropId"])
		var maxStage: int = getMaxGrowthStage(cropId)

		if cellData["growthStage"] < maxStage:
			cellData["growthStage"] += 1
			updateCropVisual(cellPosition)

			if debugLog:
				print("Crop grew at: ", cellPosition, " Stage: ", cellData["growthStage"])
		else:
			if debugLog:
				print("Crop already fully grown at: ", cellPosition)


func updateCropVisual(cellPosition: Vector2i) -> void:
	if cropVisuals.has(cellPosition) == false:
		return

	var cropVisual: Node = cropVisuals[cellPosition]

	if is_instance_valid(cropVisual) == false:
		cropVisuals.erase(cellPosition)
		return

	var cropSprite := cropVisual.get_node_or_null("CropSprite") as Sprite2D

	if cropSprite == null:
		if debugLog:
			print("CropSprite not found at: ", cellPosition)
		return

	var cellData: Dictionary = fieldData[cellPosition]
	var cropId: String = String(cellData["cropId"])
	var growthStage: int = int(cellData["growthStage"])

	if cropDatabase == null:
		refreshReferences()

	if cropDatabase == null:
		if debugLog:
			print("Cannot update crop visual: CropDatabase is null.")
		return

	var cropTexture: Texture2D = cropDatabase.getCropStageTexture(cropId, growthStage)
	cropSprite.texture = cropTexture


func removeCropVisual(cellPosition: Vector2i) -> void:
	if cropVisuals.has(cellPosition) == false:
		return

	var cropCell: Node = cropVisuals[cellPosition]

	if is_instance_valid(cropCell):
		cropCell.free()

	cropVisuals.erase(cellPosition)
	

func clearWateredCells() -> void:
	for cellPosition in fieldData.keys():
		fieldData[cellPosition]["watered"] = false

	for cellPosition in wateredVisuals.keys():
		var wateredCell: Node = wateredVisuals[cellPosition]

		if is_instance_valid(wateredCell):
			wateredCell.queue_free()

	wateredVisuals.clear()
	
	if debugLog:	
		print("Watered cells cleared")


func getSaveData() -> Dictionary:
	var cells: Array = []

	for cellPosition in fieldData.keys():
		var cellData: Dictionary = fieldData[cellPosition]

		cells.append({
			"x": cellPosition.x,
			"y": cellPosition.y,
			"cleared": cellData.get("cleared", false),
			"tilled": cellData["tilled"],
			"hoeStage": cellData.get("hoeStage", HOE_STAGE_TILLED if cellData["tilled"] else HOE_STAGE_NONE),
			"watered": cellData["watered"],
			"cropId": cellData["cropId"],
			"growthStage": cellData["growthStage"]
		})

	return {
		"cellSize": cellSize,
		"gridWidth": gridWidth,
		"gridHeight": gridHeight,
		"cells": cells
	}


func loadSaveData(saveData: Dictionary) -> void:
	clearFieldVisuals()
	initializeFieldData()

	if saveData.has("cells") == false:
		if debugLog:
			print("Field load failed: cells missing.")
		return

	var cells: Array = saveData["cells"]

	# 1차: 데이터만 전부 복원
	for cellSaveData in cells:
		var cellPosition := Vector2i(
			int(cellSaveData["x"]),
			int(cellSaveData["y"])
		)

		if isValidCell(cellPosition) == false:
			continue

		fieldData[cellPosition]["cleared"] = bool(cellSaveData.get("cleared", false))
		
		fieldData[cellPosition]["tilled"] = bool(cellSaveData["tilled"])

		fieldData[cellPosition]["hoeStage"] = int(
			cellSaveData.get(
				"hoeStage",
				HOE_STAGE_TILLED if bool(cellSaveData["tilled"]) else HOE_STAGE_NONE
			)
		)

		fieldData[cellPosition]["watered"] = bool(cellSaveData["watered"])
		fieldData[cellPosition]["cropId"] = String(cellSaveData["cropId"])
		fieldData[cellPosition]["growthStage"] = int(cellSaveData["growthStage"])

		# hoeStage와 tilled 동기화
		if int(fieldData[cellPosition]["hoeStage"]) >= HOE_STAGE_TILLED:
			fieldData[cellPosition]["tilled"] = true

	# 2차: 모든 데이터가 들어간 뒤 visual 재생성
	rebuildAllFieldVisuals()
	#generateInitialDeadGrassPatches()
	#syncClearableObjects()

	if debugLog:
		print("Field loaded.")


func clearFieldVisuals() -> void:
	for child in dryDirtPatchCells.get_children():
		child.free()
	
	for child in scratchCells.get_children():
		child.free()

	for child in partlyTilledCells.get_children():
		child.free()

	for child in tilledCells.get_children():
		child.free()

	for child in wateredCells.get_children():
		child.free()

	clearCropVisuals()

	cropVisuals.clear()
	wateredVisuals.clear()


func clearCropVisuals() -> void:
	if cropCells == null:
		refreshReferences()

	if cropCells == null:
		if debugLog:
			print("Cannot clear crop visuals: cropCells is null.")
		return

	for child in cropCells.get_children():
		if child.name.begins_with("CropVisual_"):
			child.free()

	cropVisuals.clear()
	
	
func rebuildCellVisual(cellPosition: Vector2i) -> void:
	var cellData: Dictionary = fieldData[cellPosition]
	var hoeStage: int = int(cellData.get("hoeStage", HOE_STAGE_NONE))

	if bool(cellData.get("cleared", false)) == true and hoeStage == HOE_STAGE_NONE:
		refreshDryDirtPatchVisual(cellPosition)
	
	if hoeStage == HOE_STAGE_SCRATCH:
		refreshScratchCellVisual(cellPosition)

	elif hoeStage == HOE_STAGE_PARTLY_TILLED:
		refreshPartlyTilledCellVisual(cellPosition)

	elif hoeStage >= HOE_STAGE_TILLED or cellData["tilled"] == true:
		fieldData[cellPosition]["tilled"] = true
		fieldData[cellPosition]["hoeStage"] = HOE_STAGE_TILLED
		refreshTilledCellVisual(cellPosition)

	if cellData["watered"] == true:
		refreshWateredCellVisual(cellPosition)

	if cellData["cropId"] != "":
		var cropVisual := createCropCellVisual(
			cellPosition,
			String(cellData["cropId"]),
			int(cellData["growthStage"])
		)

		cropCells.add_child(cropVisual)
		cropVisuals[cellPosition] = cropVisual


func rebuildAllFieldVisuals() -> void:
	for cellPosition in fieldData.keys():
		rebuildCellVisual(cellPosition)


func getSeedItemId(cropId: String) -> String:
	refreshReferences()

	if cropDatabase != null and cropDatabase.has_method("getSeedItemId"):
		return cropDatabase.getSeedItemId(cropId)

	return cropId + "_seed"


func getMaxGrowthStage(cropId: String) -> int:
	refreshReferences()

	if cropDatabase != null and cropDatabase.has_method("getMaxGrowthStage"):
		return cropDatabase.getMaxGrowthStage(cropId)

	return 3


func showFeedbackText(message: String) -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("showFeedbackText"):
		uiManager.showFeedbackText(message)


func showLocalizedFeedbackText(key: String, values: Array = []) -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("showLocalizedFeedbackText"):
		uiManager.showLocalizedFeedbackText(key, values)


func getCropDisplayName(cropId: String) -> String:
	refreshReferences()

	if cropDatabase == null:
		return cropId

	var localizationManager := get_tree().get_first_node_in_group("localization_manager")

	if cropDatabase.has_method("getDisplayNameKey"):
		var displayNameKey: String = cropDatabase.getDisplayNameKey(cropId)

		if displayNameKey != "" and localizationManager != null and localizationManager.has_method("trText"):
			return localizationManager.trText(displayNameKey)

	if cropDatabase.has_method("getDisplayName"):
		return cropDatabase.getDisplayName(cropId)

	return cropId


func isCellTilled(cellPosition: Vector2i) -> bool:
	if not fieldData.has(cellPosition):
		return false
	
	var cellData: Dictionary = fieldData[cellPosition]
	return bool(cellData.get("tilled", false))


func getTilledTextureForCell(cellPosition: Vector2i) -> Texture2D:
	var up := isCellTilled(cellPosition + Vector2i(0, -1))
	var right := isCellTilled(cellPosition + Vector2i(1, 0))
	var down := isCellTilled(cellPosition + Vector2i(0, 1))
	var left := isCellTilled(cellPosition + Vector2i(-1, 0))
	
	var count := 0
	if up:
		count += 1
	if right:
		count += 1
	if down:
		count += 1
	if left:
		count += 1
	
	if count == 0:
		return TILLED_SINGLE
	
	if count == 1:
		if up:
			return TILLED_END_DOWN
		if right:
			return TILLED_END_LEFT
		if down:
			return TILLED_END_UP
		if left:
			return TILLED_END_RIGHT
	
	if count == 2:
		if left and right:
			return TILLED_LINE_H
		if up and down:
			return TILLED_LINE_V
		
		if up and right:
			return TILLED_CORNER_DOWN_LEFT
		if right and down:
			return TILLED_CORNER_UP_LEFT
		if down and left:
			return TILLED_CORNER_UP_RIGHT
		if left and up:
			return TILLED_CORNER_DOWN_RIGHT
	
	if count == 3:
		if up and right and left:
			return TILLED_T_UP
		if up and right and down:
			return TILLED_T_RIGHT
		if right and down and left:
			return TILLED_T_DOWN
		if down and left and up:
			return TILLED_T_LEFT
	
	return TILLED_CENTER


func getDryDirtPatchTextureForCell(cellPosition: Vector2i) -> Texture2D:
	var index: int = abs(int(hash(str(cellPosition) + "_dry_dirt"))) % 4

	match index:
		0:
			return DRY_DIRT_PATCH_01
		1:
			return DRY_DIRT_PATCH_02
		2:
			return DRY_DIRT_PATCH_03
		_:
			return DRY_DIRT_PATCH_04


func refreshDryDirtPatchVisual(cellPosition: Vector2i) -> void:
	var nodeName := "DryDirt_%s_%s" % [cellPosition.x, cellPosition.y]
	var existing := dryDirtPatchCells.get_node_or_null(nodeName)

	if existing == null:
		var sprite := Sprite2D.new()
		sprite.name = nodeName
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = getCellLocalCenter(cellPosition)
		dryDirtPatchCells.add_child(sprite)
		existing = sprite

	existing.texture = getDryDirtPatchTextureForCell(cellPosition)


func clearGroundAtWorldPosition(worldPosition: Vector2) -> void:
	var cellPosition := worldToCell(worldPosition)

	if isValidCell(cellPosition) == false:
		return

	clearGroundAtCell(cellPosition)


func clearGroundAtCell(cellPosition: Vector2i) -> void:
	var cellData: Dictionary = fieldData[cellPosition]

	if bool(cellData.get("tilled", false)) == true:
		return

	cellData["cleared"] = true

	if int(cellData.get("hoeStage", HOE_STAGE_NONE)) == HOE_STAGE_NONE:
		refreshDryDirtPatchVisual(cellPosition)

	if debugLog:
		print("Cleared ground at: ", cellPosition)


func isGroundClearedAtWorldPosition(worldPosition: Vector2) -> bool:
	var cellPosition := worldToCell(worldPosition)

	if isValidCell(cellPosition) == false:
		return false

	var cellData: Dictionary = fieldData[cellPosition]
	return bool(cellData.get("cleared", false))


#func syncClearableObjects() -> void:
	#var clearableObjects := get_tree().get_nodes_in_group("clearable_object")
#
	#for clearable in clearableObjects:
		#if clearable.has_method("syncWithFieldArea"):
			#clearable.syncWithFieldArea()


#func generateInitialDeadGrassPatches() -> void:
	#if deadGrassPatchScene == null:
		#if debugLog:
			#print("DeadGrassPatch scene is not assigned.")
		#return
#
	#if clearableObjectsRoot == null:
		#clearableObjectsRoot = get_node_or_null(clearableObjectsRootPath) as Node2D
#
	#if clearableObjectsRoot == null:
		#if debugLog:
			#print("ClearableObjects root not found.")
		#return
#
	#clearGeneratedDeadGrassPatches()
#
	#for y in range(gridHeight):
		#for x in range(gridWidth):
			#var cellPosition := Vector2i(x, y)
#
			#if shouldSpawnDeadGrassAtCell(cellPosition) == false:
				#continue
#
			#var cellData: Dictionary = fieldData[cellPosition]
#
			#if bool(cellData.get("cleared", false)) == true:
				#continue
#
			#if bool(cellData.get("tilled", false)) == true:
				#continue
#
			#var patch := deadGrassPatchScene.instantiate() as Node2D
			#patch.name = "DeadGrassPatch_%d_%d" % [cellPosition.x, cellPosition.y]
			#patch.global_position = cellToWorldCenter(cellPosition) + getDeadGrassOffset(cellPosition)
#
			#clearableObjectsRoot.add_child(patch)


#func clearGeneratedDeadGrassPatches() -> void:
	#if clearableObjectsRoot == null:
		#return
#
	#for child in clearableObjectsRoot.get_children():
		#if child.name.begins_with("DeadGrassPatch_"):
			#child.free()


#func shouldSpawnDeadGrassAtCell(cellPosition: Vector2i) -> bool:
	#var value: int = abs(int(hash(str(cellPosition) + "_dead_grass_spawn"))) % 100
	#return value < deadGrassSpawnChance


#func getDeadGrassOffset(cellPosition: Vector2i) -> Vector2:
	#var hashX: int = abs(int(hash(str(cellPosition) + "_dead_grass_offset_x")))
	#var hashY: int = abs(int(hash(str(cellPosition) + "_dead_grass_offset_y")))
#
	#var offsetX: float = float((hashX % 17) - 8) # -8 ~ +8
	#var offsetY: float = float((hashY % 11) - 5) # -5 ~ +5
#
	#return Vector2(offsetX, offsetY)
