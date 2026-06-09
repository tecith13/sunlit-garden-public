extends Node2D

@export var debugLog: bool = false

@export var groundPath: NodePath
@onready var groundNode: Node2D = get_node_or_null(groundPath) as Node2D

@export var boundsRootPath: NodePath
@onready var boundsRoot: Node2D = get_node_or_null(boundsRootPath) as Node2D

@export var cellSize: int = 16
@export_range(0, 100) var deadGrassSpawnChance: int = 18
@export_range(0, 100) var deadGrassScatterChance: int = 55
@export_range(0, 100) var breathingSpaceChance: int = 4

@export var deadGrassPatchScene: PackedScene
@export var deadGrassScatterSmallScene: PackedScene
@export var clearableObjectsRootPath: NodePath

@onready var clearableObjectsRoot: Node2D = get_node_or_null(clearableObjectsRootPath) as Node2D

@export_range(0, 100) var dailyRegrowChance: int = 8
@export var maxDailyRegrowCount: int = 4
@export var regrowCooldownDays: int = 3

var worldAreaManager: WorldAreaManager = null
var terrainManager: TerrainManager = null
var worldGrid: WorldGrid = null

@export var useWorldAreaSpawn: bool = true

@export var vegetationSpawnAreaIds: Array[String] = [
	"start_dead_grass_area"
]
@export var filterSpawnToWalledGardenInterior: bool = true
@export var walledGardenInteriorAreaId: String = "walled_garden_interior_area"
@export var skipLoadedVegetationOutsideWalledGardenInterior: bool = true

@export var vegetationExcludeAreaIds: Array[String] = [
	#"house_plot",
	# Keep ruined_garden_area available for terrain/debug/layout; use smaller
	# dedicated exclude areas if specific ruined garden spots must stay clear.
	"mailbox_area",
	"old_stone_road_area",
	"village_square_area",
	"seed_stall_area",
	"shipping_trade_area",
	"furniture_workshop_area",
	"temporary_housing_area",
	"teahouse_area",
	"external_road_area"
]

@export var worldAreaCandidateStep: int = 1
@export var maxVegetationCandidateChecks: int = 8000
@export var maxDeadGrassPatchCount: int = 320
@export var maxDeadGrassScatterCount: int = 200
@export var useClusteredDeadGrassSpawn: bool = false
@export var deadGrassClusterCount: int = 35
@export var deadGrassClusterRadiusCells: int = 7
@export var patchPerClusterMin: int = 4
@export var patchPerClusterMax: int = 7
@export var scatterPerClusterMin: int = 4
@export var scatterPerClusterMax: int = 10

var player: Node2D = null
# 제거된 풀 ID 저장
var clearedVegetationIds: Array[String] = []
# 날짜가 지나 새로생긴 풀 저장
var grownVegetationIds: Array[String] = []
# 풀 제거 날짜 저장
var clearedVegetationDays: Dictionary = {}


var spawnedVegetation: Array[Dictionary] = []

const VEGETATION_TYPE_DEAD_GRASS_PATCH := "DeadGrassPatch"
const VEGETATION_TYPE_DEAD_GRASS_SCATTER := "DeadGrassScatter"


func _ready() -> void:
	refreshReferences()
	
	add_to_group("vegetation_spawner")
	
	call_deferred("generateDeadGrassPatches")

	if debugLog:
		print("VegetationSpawner ready")


func startNewVegetation() -> void:
	clearedVegetationIds.clear()
	grownVegetationIds.clear()
	clearedVegetationDays.clear()
	spawnedVegetation.clear()
	generateDeadGrassPatches()


func generateDeadGrassPatches() -> void:
	refreshReferences()
	
	var candidateCells: Array[Vector2i] = getVegetationCandidateCells()
	
	if useWorldAreaSpawn:
		print("VegetationSpawner world-area candidate cells before limit: ", candidateCells.size())
		printWalledGardenInteriorDebug()
		printCandidateCellsDebug(candidateCells, "before limit")
	else:
		var worldRect: Rect2 = getWorldBoundsRect()
		print("Ground bounds rect: ", worldRect)
		print("VegetationSpawner ground-bounds candidate cells before limit: ", candidateCells.size())
	
	if clearableObjectsRoot == null:
		clearableObjectsRoot = get_node_or_null(clearableObjectsRootPath) as Node2D

	if clearableObjectsRoot == null:
		if debugLog:
			print("ClearableObjects root not found.")
		return

	clearGeneratedDeadGrassPatches()
	spawnedVegetation.clear()

	candidateCells.shuffle()

	if maxVegetationCandidateChecks > 0 and candidateCells.size() > maxVegetationCandidateChecks:
		candidateCells = candidateCells.slice(0, maxVegetationCandidateChecks)

	print("VegetationSpawner candidate cells after limit: ", candidateCells.size())
	printCandidateCellsDebug(candidateCells, "after limit")

	if useClusteredDeadGrassSpawn:
		generateClusteredDeadGrassPatches(candidateCells)
		return

	generateUniformDeadGrassPatches(candidateCells)


func generateUniformDeadGrassPatches(candidateCells: Array[Vector2i]) -> void:
	var spawnedPatchCount: int = 0
	var spawnedScatterCount: int = 0

	for worldCell in candidateCells:
		if spawnedPatchCount >= maxDeadGrassPatchCount and spawnedScatterCount >= maxDeadGrassScatterCount:
			break

		if shouldSkipForBreathingSpace(worldCell):
			continue

		if spawnedPatchCount < maxDeadGrassPatchCount and deadGrassPatchScene != null and shouldSpawnDeadGrassAtCell(worldCell):
			if spawnDeadGrassPatchByCell(worldCell):
				spawnedPatchCount += 1

		if spawnedScatterCount < maxDeadGrassScatterCount and deadGrassScatterSmallScene != null and shouldSpawnDeadGrassScatterAtCell(worldCell):
			if spawnDeadGrassScatterByCell(worldCell):
				spawnedScatterCount += 1


func generateClusteredDeadGrassPatches(candidateCells: Array[Vector2i]) -> void:
	var clusterCenters: Array[Vector2i] = getDeadGrassClusterCenters(candidateCells)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash("dead_grass_cluster_seed_" + str(candidateCells.size()))))
	var spawnedPatchCount: int = 0
	var spawnedScatterCount: int = 0

	for clusterCenter in clusterCenters:
		if spawnedPatchCount >= maxDeadGrassPatchCount and spawnedScatterCount >= maxDeadGrassScatterCount:
			break

		var patchMin: int = min(patchPerClusterMin, patchPerClusterMax)
		var patchMax: int = max(patchPerClusterMin, patchPerClusterMax)
		var scatterMin: int = min(scatterPerClusterMin, scatterPerClusterMax)
		var scatterMax: int = max(scatterPerClusterMin, scatterPerClusterMax)
		var patchTarget: int = rng.randi_range(patchMin, patchMax)
		var scatterTarget: int = rng.randi_range(scatterMin, scatterMax)
		var clusterPatchCells: Array[Vector2i] = []
		var patchAttempts: int = max(patchTarget * 8, 12)

		while patchTarget > 0 and patchAttempts > 0 and spawnedPatchCount < maxDeadGrassPatchCount:
			patchAttempts -= 1
			var patchCell: Vector2i = getRandomCellNearClusterCenter(clusterCenter, deadGrassClusterRadiusCells, rng)

			if canUseCellForDeadGrassCluster(patchCell) == false:
				continue

			if spawnDeadGrassPatchByCell(patchCell):
				clusterPatchCells.append(patchCell)
				spawnedPatchCount += 1
				patchTarget -= 1

		var scatterAttempts: int = max(scatterTarget * 8, 20)

		while scatterTarget > 0 and scatterAttempts > 0 and spawnedScatterCount < maxDeadGrassScatterCount:
			scatterAttempts -= 1
			var scatterAnchor: Vector2i = clusterCenter

			if clusterPatchCells.is_empty() == false:
				scatterAnchor = clusterPatchCells[rng.randi_range(0, clusterPatchCells.size() - 1)]

			var scatterCell: Vector2i = getRandomCellNearClusterCenter(
				scatterAnchor,
				max(2, deadGrassClusterRadiusCells - 1),
				rng
			)

			if canUseCellForDeadGrassCluster(scatterCell) == false:
				continue

			if spawnDeadGrassScatterByCell(scatterCell):
				spawnedScatterCount += 1
				scatterTarget -= 1


func getDeadGrassClusterCenters(candidateCells: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var areaCenter: Vector2i = getDeadGrassClusterAreaCenter(candidateCells)
	var centerOffsets: Array[Vector2i] = [
		Vector2i(-22, -14),
		Vector2i(20, -14),
		Vector2i(-26, 4),
		Vector2i(24, 6),
		Vector2i(-16, 20),
		Vector2i(16, 22),
		Vector2i(0, 28)
	]

	for offset in centerOffsets:
		if result.size() >= deadGrassClusterCount:
			break

		var center: Vector2i = areaCenter + offset
		result.append(findNearestUsableClusterCell(center, candidateCells))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash("dead_grass_extra_cluster_centers_" + str(candidateCells.size()))))

	while result.size() < deadGrassClusterCount and candidateCells.is_empty() == false:
		var index: int = rng.randi_range(0, candidateCells.size() - 1)
		result.append(candidateCells[index])

	return result


func getDeadGrassClusterAreaCenter(candidateCells: Array[Vector2i]) -> Vector2i:
	if worldAreaManager != null and filterSpawnToWalledGardenInterior and worldAreaManager.hasArea(walledGardenInteriorAreaId):
		return worldAreaManager.getAreaCenterCell(walledGardenInteriorAreaId)

	if worldAreaManager != null and worldAreaManager.hasArea("start_dead_grass_area"):
		return worldAreaManager.getAreaCenterCell("start_dead_grass_area")

	if worldAreaManager != null and worldAreaManager.hasArea("player_home_area"):
		return worldAreaManager.getAreaCenterCell("player_home_area")

	if candidateCells.is_empty():
		return Vector2i.ZERO

	var sum := Vector2i.ZERO

	for cell in candidateCells:
		sum += cell

	return Vector2i(
		roundi(float(sum.x) / float(candidateCells.size())),
		roundi(float(sum.y) / float(candidateCells.size()))
	)


func findNearestUsableClusterCell(targetCell: Vector2i, candidateCells: Array[Vector2i]) -> Vector2i:
	if canUseCellForDeadGrassCluster(targetCell):
		return targetCell

	var bestCell: Vector2i = targetCell
	var bestDistance: int = 2147483647

	for cell in candidateCells:
		var distance: int = abs(cell.x - targetCell.x) + abs(cell.y - targetCell.y)

		if distance < bestDistance:
			bestDistance = distance
			bestCell = cell

	return bestCell


func getRandomCellNearClusterCenter(centerCell: Vector2i, radiusCells: int, rng: RandomNumberGenerator) -> Vector2i:
	var radius: int = max(1, radiusCells)
	var offsetX: int = rng.randi_range(-radius, radius)
	var offsetY: int = rng.randi_range(-radius, radius)

	return centerCell + Vector2i(offsetX, offsetY)


func canUseCellForDeadGrassCluster(cell: Vector2i) -> bool:
	if canUseCellForVegetation(cell) == false:
		return false

	if worldAreaManager == null:
		return true

	for areaId in vegetationSpawnAreaIds:
		if worldAreaManager.hasArea(areaId) and worldAreaManager.isCellInArea(cell, areaId):
			return true

	return false


func isCellInsideWalledGardenInterior(cell: Vector2i) -> bool:
	if filterSpawnToWalledGardenInterior == false:
		return true

	if worldAreaManager == null:
		return true

	if walledGardenInteriorAreaId == "":
		return true

	if worldAreaManager.hasArea(walledGardenInteriorAreaId) == false:
		if debugLog:
			print("VegetationSpawner: missing walled garden area id: ", walledGardenInteriorAreaId)
		return true

	return worldAreaManager.isCellInArea(cell, walledGardenInteriorAreaId)


func shouldSkipLoadedVegetationCell(cell: Vector2i) -> bool:
	if skipLoadedVegetationOutsideWalledGardenInterior == false:
		return false

	return isCellInsideWalledGardenInterior(cell) == false


func printWalledGardenInteriorDebug() -> void:
	if debugLog == false:
		return

	if worldAreaManager == null:
		print("VegetationSpawner walled garden filter: WorldAreaManager is null.")
		return

	if filterSpawnToWalledGardenInterior == false:
		print("VegetationSpawner walled garden filter disabled.")
		return

	if worldAreaManager.hasArea(walledGardenInteriorAreaId) == false:
		print("VegetationSpawner walled garden filter missing area: ", walledGardenInteriorAreaId)
		return

	var rect: Rect2i = worldAreaManager.getAreaRect(walledGardenInteriorAreaId)
	print("VegetationSpawner walled garden interior rect: ", rect)


func printCandidateCellsDebug(candidateCells: Array[Vector2i], label: String) -> void:
	if debugLog == false:
		return

	if candidateCells.is_empty():
		print("VegetationSpawner candidate cells ", label, ": empty")
		return

	var minCell: Vector2i = candidateCells[0]
	var maxCell: Vector2i = candidateCells[0]

	for cell in candidateCells:
		minCell.x = min(minCell.x, cell.x)
		minCell.y = min(minCell.y, cell.y)
		maxCell.x = max(maxCell.x, cell.x)
		maxCell.y = max(maxCell.y, cell.y)

	print("VegetationSpawner candidate cells ", label, " bounds min:", minCell, " max:", maxCell)


func trySpawnDeadGrassPatch(worldCell: Vector2i) -> void:
	spawnDeadGrassPatchByCell(worldCell)


func trySpawnDeadGrassScatter(worldCell: Vector2i) -> void:
	spawnDeadGrassScatterByCell(worldCell)


func clearGeneratedDeadGrassPatches() -> void:
	if clearableObjectsRoot == null:
		return

	for child in clearableObjectsRoot.get_children():
		if child.name.begins_with("DeadGrassPatch_") or child.name.begins_with("DeadGrassScatter_"):
			child.free()


func isVegetationCleared(vegetationId: String) -> bool:
	return clearedVegetationIds.has(vegetationId)


func markVegetationCleared(vegetationId: String) -> void:
	if vegetationId == "":
		return

	var gameManager := get_tree().get_first_node_in_group("game_manager")
	var currentDay: int = 1

	if gameManager != null:
		currentDay = int(gameManager.currentDay)

	if clearedVegetationIds.has(vegetationId) == false:
		clearedVegetationIds.append(vegetationId)

	clearedVegetationDays[vegetationId] = currentDay

	# 중요:
	# 날짜 경과로 자란 식생을 제거했다면,
	# 현재 자라 있는 목록에서는 제거해야 함.
	if grownVegetationIds.has(vegetationId):
		grownVegetationIds.erase(vegetationId)

	if debugLog:
		print("Marked vegetation cleared: ", vegetationId, " day: ", currentDay)


func canRegrowClearedVegetation(vegetationId: String, currentDay: int) -> bool:
	if clearedVegetationDays.has(vegetationId) == false:
		return false

	var clearedDay: int = int(clearedVegetationDays[vegetationId])
	return currentDay - clearedDay >= regrowCooldownDays


func shouldSpawnDeadGrassAtCell(cellPosition: Vector2i) -> bool:
	var regionCell := Vector2i(
		floori(float(cellPosition.x) / 3.0),
		floori(float(cellPosition.y) / 3.0)
	)

	var regionValue: int = abs(int(hash(str(regionCell) + "_dead_grass_region"))) % 100
	var localChance: int = deadGrassSpawnChance

	if regionValue < 25:
		localChance += 18
	elif regionValue < 55:
		localChance += 4
	else:
		localChance -= 10

	localChance = clamp(localChance, 0, 75)

	var value: int = abs(int(hash(str(cellPosition) + "_dead_grass_spawn"))) % 100
	return value < localChance


func getDeadGrassOffset(cellPosition: Vector2i) -> Vector2:
	var hashX: int = abs(int(hash(str(cellPosition) + "_dead_grass_offset_x")))
	var hashY: int = abs(int(hash(str(cellPosition) + "_dead_grass_offset_y")))

	var offsetX: float = float((hashX % 29) - 14)
	var offsetY: float = float((hashY % 17) - 8)

	return Vector2(offsetX, offsetY)


func isSpawnPositionBlocked(spawnPosition: Vector2) -> bool:
	# 로드/재생성 결과가 플레이어 현재 위치에 따라 달라지면 안 됨.
	# 플레이어 시작 위치 보호는 SpawnBlocker Area2D로 처리한다.
	# if avoidPlayerStart and player != null:
	# 	var distanceToPlayer: float = player.global_position.distance_to(spawnPosition)
	#
	# 	if distanceToPlayer < playerAvoidRadius:
	# 		return true

	if isInsideVegetationBlocker(spawnPosition):
		return true

	return false


func shouldSkipForBreathingSpace(cellPosition: Vector2i) -> bool:
	var value: int = abs(int(hash(str(cellPosition) + "_breathing_space"))) % 100
	return value < breathingSpaceChance


func shouldSpawnDeadGrassScatterAtCell(cellPosition: Vector2i) -> bool:
	var value: int = abs(int(hash(str(cellPosition) + "_dead_grass_scatter_spawn"))) % 100
	return value < deadGrassScatterChance


func getDeadGrassScatterOffset(cellPosition: Vector2i) -> Vector2:
	var hashX: int = abs(int(hash(str(cellPosition) + "_dead_grass_scatter_offset_x")))
	var hashY: int = abs(int(hash(str(cellPosition) + "_dead_grass_scatter_offset_y")))

	var offsetX: float = float((hashX % 33) - 16)
	var offsetY: float = float((hashY % 21) - 10)

	return Vector2(offsetX, offsetY)


func isInsideVegetationBlocker(worldPosition: Vector2) -> bool:
	var blockers := get_tree().get_nodes_in_group("vegetation_spawn_blocker")

	for blocker in blockers:
		if blocker is Area2D == false:
			continue

		var blockerArea := blocker as Area2D

		for shapeOwnerId in blockerArea.get_shape_owners():
			var ownerTransform: Transform2D = blockerArea.shape_owner_get_transform(shapeOwnerId)
			var shapeCount: int = blockerArea.shape_owner_get_shape_count(shapeOwnerId)

			for i in range(shapeCount):
				var shape := blockerArea.shape_owner_get_shape(shapeOwnerId, i)

				if shape is RectangleShape2D:
					var rectangleShape := shape as RectangleShape2D
					var globalCenter: Vector2 = blockerArea.global_transform * ownerTransform.origin
					var rect := Rect2(
						globalCenter - rectangleShape.size / 2.0,
						rectangleShape.size
					)

					if rect.has_point(worldPosition):
						return true

	return false


func getSaveData() -> Dictionary:
	return {
		"clearedVegetationIds": clearedVegetationIds.duplicate(),
		"clearedVegetationDays": clearedVegetationDays.duplicate(),
		"grownVegetationIds": grownVegetationIds.duplicate(),
		"spawnedVegetation": getSpawnedVegetationSaveData()
	}


func loadSaveData(saveData: Dictionary) -> void:
	clearedVegetationIds.clear()
	grownVegetationIds.clear()
	clearedVegetationDays.clear()
	
	if saveData.has("clearedVegetationIds"):
		for id in saveData["clearedVegetationIds"]:
			clearedVegetationIds.append(String(id))

	if saveData.has("clearedVegetationDays"):
		var savedDays: Dictionary = saveData["clearedVegetationDays"]

		for key in savedDays.keys():
			clearedVegetationDays[String(key)] = int(savedDays[key])
			
	if saveData.has("grownVegetationIds"):
		for id in saveData["grownVegetationIds"]:
			grownVegetationIds.append(String(id))

	if saveData.has("spawnedVegetation") and saveData["spawnedVegetation"] is Array:
		restoreSpawnedVegetation(saveData["spawnedVegetation"])
	else:
		generateDeadGrassPatches()

	generateGrownVegetationPatches()

	if debugLog:
		print(
			"Vegetation loaded. Cleared count: ",
			clearedVegetationIds.size(),
			" Grown count: ",
			grownVegetationIds.size()
		)


func getSpawnedVegetationSaveData() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for entry in spawnedVegetation:
		var normalizedEntry := normalizeSpawnedVegetationEntry(entry)

		if normalizedEntry.is_empty():
			continue

		var vegetationId: String = str(normalizedEntry.get("id", ""))
		normalizedEntry["cleared"] = isVegetationCleared(vegetationId) or isSpawnedVegetationNodeCleared(vegetationId)
		normalizedEntry["soilState"] = getSpawnedVegetationNodeSoilState(
			vegetationId,
			str(normalizedEntry.get("soilState", "dry"))
		)
		result.append(normalizedEntry)

	return result


func restoreSpawnedVegetation(savedEntries: Array) -> void:
	refreshReferences()

	if clearableObjectsRoot == null:
		clearableObjectsRoot = get_node_or_null(clearableObjectsRootPath) as Node2D

	if clearableObjectsRoot == null:
		if debugLog:
			print("ClearableObjects root not found while restoring vegetation.")
		return

	clearGeneratedDeadGrassPatches()
	spawnedVegetation.clear()

	for savedEntry in savedEntries:
		if savedEntry is Dictionary == false:
			continue

		var entry := normalizeSpawnedVegetationEntry(savedEntry)

		if entry.is_empty():
			continue

		var vegetationId: String = str(entry.get("id", ""))
		var worldCell: Vector2i = parseVegetationCell(entry.get("cell", []), vegetationId)

		if shouldSkipLoadedVegetationCell(worldCell):
			if debugLog:
				print("Skipping loaded vegetation outside walled garden interior: ", vegetationId, " cell: ", worldCell)
			continue

		var shouldBeCleared: bool = bool(entry.get("cleared", false)) or isVegetationCleared(vegetationId)

		if shouldBeCleared and clearedVegetationIds.has(vegetationId) == false:
			clearedVegetationIds.append(vegetationId)

		restoreVegetationEntry(entry, shouldBeCleared)


func restoreVegetationEntry(entry: Dictionary, shouldBeCleared: bool) -> bool:
	var vegetationId: String = str(entry.get("id", ""))
	var vegetationType: String = str(entry.get("type", ""))
	var worldCell: Vector2i = parseVegetationCell(entry.get("cell", []), vegetationId)
	var spawnPosition: Vector2 = parseVegetationPosition(entry.get("position", []), vegetationType, worldCell)
	var scene: PackedScene = getSceneForVegetationType(vegetationType)

	if vegetationId == "" or scene == null:
		return false

	if clearableObjectsRoot.get_node_or_null(vegetationId) != null:
		return false

	var node := scene.instantiate() as Node2D

	if node == null:
		return false

	node.name = vegetationId
	node.global_position = spawnPosition
	clearableObjectsRoot.add_child(node)

	if node.has_method("setCleared"):
		node.call("setCleared", shouldBeCleared)
	elif node is CanvasItem:
		(node as CanvasItem).visible = not shouldBeCleared

	if node.has_method("setSoilState"):
		node.call("setSoilState", str(entry.get("soilState", "dry")))

	upsertSpawnedVegetation(vegetationId, vegetationType, worldCell, spawnPosition)
	return true


func normalizeSpawnedVegetationEntry(entry: Dictionary) -> Dictionary:
	var vegetationId: String = str(entry.get("id", ""))
	var vegetationType: String = str(entry.get("type", entry.get("sceneType", "")))

	if vegetationType == "":
		vegetationType = getVegetationTypeFromId(vegetationId)

	if vegetationId == "" or vegetationType == "":
		return {}

	var worldCell: Vector2i = parseVegetationCell(entry.get("cell", []), vegetationId)
	var spawnPosition: Vector2 = parseVegetationPosition(entry.get("position", []), vegetationType, worldCell)

	return makeSpawnedVegetationEntry(
		vegetationId,
		vegetationType,
		worldCell,
		spawnPosition,
		bool(entry.get("cleared", false)),
		str(entry.get("soilState", "dry"))
	)


func makeSpawnedVegetationEntry(
	vegetationId: String,
	vegetationType: String,
	worldCell: Vector2i,
	spawnPosition: Vector2,
	isCleared: bool = false,
	soilState: String = "dry"
) -> Dictionary:
	return {
		"id": vegetationId,
		"type": vegetationType,
		"cell": [worldCell.x, worldCell.y],
		"position": [spawnPosition.x, spawnPosition.y],
		"cleared": isCleared,
		"soilState": soilState
	}


func upsertSpawnedVegetation(
	vegetationId: String,
	vegetationType: String,
	worldCell: Vector2i,
	spawnPosition: Vector2
) -> void:
	var entry := makeSpawnedVegetationEntry(
		vegetationId,
		vegetationType,
		worldCell,
		spawnPosition,
		isVegetationCleared(vegetationId),
		getSpawnedVegetationNodeSoilState(vegetationId, "dry")
	)

	for i in range(spawnedVegetation.size()):
		if str(spawnedVegetation[i].get("id", "")) == vegetationId:
			spawnedVegetation[i] = entry
			return

	spawnedVegetation.append(entry)


func isSpawnedVegetationNodeCleared(vegetationId: String) -> bool:
	if clearableObjectsRoot == null:
		return false

	var existing := clearableObjectsRoot.get_node_or_null(vegetationId)

	if existing == null:
		return false

	if existing.has_method("isCleared"):
		return bool(existing.call("isCleared"))

	return false


func getSpawnedVegetationNodeSoilState(vegetationId: String, defaultState: String = "dry") -> String:
	if clearableObjectsRoot == null:
		return defaultState

	var existing := clearableObjectsRoot.get_node_or_null(vegetationId)

	if existing == null:
		return defaultState

	if existing.has_method("getSoilState"):
		return str(existing.call("getSoilState"))

	return defaultState


func getSpawnedVegetationSoilState(vegetationId: String, defaultState: String = "dry") -> String:
	var nodeState: String = getSpawnedVegetationNodeSoilState(vegetationId, "")

	if nodeState != "":
		return nodeState

	for entry in spawnedVegetation:
		if str(entry.get("id", "")) == vegetationId:
			return str(entry.get("soilState", defaultState))

	return defaultState


func syncSpawnedVegetationSoilState(vegetationId: String, soilState: String) -> void:
	for i in range(spawnedVegetation.size()):
		if str(spawnedVegetation[i].get("id", "")) != vegetationId:
			continue

		spawnedVegetation[i]["soilState"] = soilState
		return


func getVegetationTypeFromId(vegetationId: String) -> String:
	var parts := vegetationId.split("_")

	if parts.size() < 1:
		return ""

	return String(parts[0])


func parseVegetationCell(value, vegetationId: String) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))

	if value is Vector2i:
		return Vector2i(value.x, value.y)

	if value is Vector2:
		return Vector2i(int(value.x), int(value.y))

	if value is Dictionary:
		return Vector2i(int(value.get("x", 0)), int(value.get("y", 0)))

	var parts := vegetationId.split("_")

	if parts.size() == 3:
		return Vector2i(int(parts[1]), int(parts[2]))

	return Vector2i.ZERO


func parseVegetationPosition(value, vegetationType: String, worldCell: Vector2i) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))

	if value is Vector2:
		return Vector2(float(value.x), float(value.y))

	if value is Vector2i:
		return Vector2(float(value.x), float(value.y))

	if value is Dictionary:
		return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_PATCH:
		return vegetationCellToWorldCenter(worldCell) + getDeadGrassOffset(worldCell)

	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_SCATTER:
		return vegetationCellToWorldCenter(worldCell) + getDeadGrassScatterOffset(worldCell)

	return vegetationCellToWorldCenter(worldCell)


func getSceneForVegetationType(vegetationType: String) -> PackedScene:
	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_PATCH:
		return deadGrassPatchScene

	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_SCATTER:
		return deadGrassScatterSmallScene

	return null


func generateGrownVegetationPatches() -> void:
	for vegetationId in grownVegetationIds:
		if isVegetationCleared(vegetationId):
			continue

		spawnVegetationById(vegetationId)


func spawnVegetationById(vegetationId: String) -> bool:
	var parts := vegetationId.split("_")

	if parts.size() != 3:
		return false

	var vegetationType: String = String(parts[0])
	var worldCell := Vector2i(
		int(parts[1]),
		int(parts[2])
	)

	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_PATCH:
		return spawnDeadGrassPatchByCell(worldCell)

	if vegetationType == VEGETATION_TYPE_DEAD_GRASS_SCATTER:
		return spawnDeadGrassScatterByCell(worldCell)

	return false


func spawnDeadGrassPatchByCell(worldCell: Vector2i) -> bool:
	var patchId := "DeadGrassPatch_%d_%d" % [worldCell.x, worldCell.y]

	if isVegetationCleared(patchId):
		return false

	if deadGrassPatchScene == null:
		return false

	var spawnPosition := vegetationCellToWorldCenter(worldCell) + getDeadGrassOffset(worldCell)

	if isSpawnPositionBlocked(spawnPosition):
		return false

	var existing := clearableObjectsRoot.get_node_or_null(patchId)

	if existing != null:
		if existing.has_method("isCleared") and bool(existing.call("isCleared")):
			existing.global_position = spawnPosition

			if existing.has_method("setCleared"):
				existing.call("setCleared", false)

			upsertSpawnedVegetation(patchId, VEGETATION_TYPE_DEAD_GRASS_PATCH, worldCell, spawnPosition)
			return true

		if existing is CanvasItem and existing.visible == false:
			existing.global_position = spawnPosition

			if existing.has_method("setCleared"):
				existing.call("setCleared", false)
			else:
				existing.visible = true

			upsertSpawnedVegetation(patchId, VEGETATION_TYPE_DEAD_GRASS_PATCH, worldCell, spawnPosition)
			return true

		return false

	var patch := deadGrassPatchScene.instantiate() as Node2D
	patch.name = patchId
	patch.global_position = spawnPosition
	clearableObjectsRoot.add_child(patch)
	upsertSpawnedVegetation(patchId, VEGETATION_TYPE_DEAD_GRASS_PATCH, worldCell, spawnPosition)

	return true


func spawnDeadGrassScatterByCell(worldCell: Vector2i) -> bool:
	var scatterId := "DeadGrassScatter_%d_%d" % [worldCell.x, worldCell.y]

	if isVegetationCleared(scatterId):
		return false

	if deadGrassScatterSmallScene == null:
		return false

	var scatterPosition := vegetationCellToWorldCenter(worldCell) + getDeadGrassScatterOffset(worldCell)

	if isSpawnPositionBlocked(scatterPosition):
		return false

	var existing := clearableObjectsRoot.get_node_or_null(scatterId)

	if existing != null:
		if existing.has_method("isCleared") and bool(existing.call("isCleared")):
			existing.global_position = scatterPosition

			if existing.has_method("setCleared"):
				existing.call("setCleared", false)

			upsertSpawnedVegetation(scatterId, VEGETATION_TYPE_DEAD_GRASS_SCATTER, worldCell, scatterPosition)
			return true

		if existing is CanvasItem and existing.visible == false:
			existing.global_position = scatterPosition

			if existing.has_method("setCleared"):
				existing.call("setCleared", false)
			else:
				existing.visible = true

			upsertSpawnedVegetation(scatterId, VEGETATION_TYPE_DEAD_GRASS_SCATTER, worldCell, scatterPosition)
			return true

		return false

	var scatter := deadGrassScatterSmallScene.instantiate() as Node2D
	scatter.name = scatterId
	scatter.global_position = scatterPosition
	clearableObjectsRoot.add_child(scatter)
	upsertSpawnedVegetation(scatterId, VEGETATION_TYPE_DEAD_GRASS_SCATTER, worldCell, scatterPosition)

	return true


func vegetationCellToWorldCenter(cellPosition: Vector2i) -> Vector2:
	return Vector2(
		cellPosition.x * cellSize + cellSize / 2.0,
		cellPosition.y * cellSize + cellSize / 2.0
	)


func processNextDay(currentDay: int) -> void:
	if debugLog:
		print("VegetationSpawner processNextDay called. Day: ", currentDay)
	recoverWateredSoilPatches(currentDay)
	regrowVegetationForDay(currentDay)


func recoverWateredSoilPatches(_currentDay: int) -> void:
	if clearableObjectsRoot == null:
		clearableObjectsRoot = get_node_or_null(clearableObjectsRootPath) as Node2D

	if clearableObjectsRoot == null:
		return

	for child in clearableObjectsRoot.get_children():
		if child == null:
			continue

		if child.has_method("isCleared") == false:
			continue

		if bool(child.call("isCleared")) == false:
			continue

		if child.has_method("getSoilState") == false:
			continue

		if str(child.call("getSoilState")) != "watered":
			continue

		if child.has_method("setSoilState"):
			child.call("setSoilState", "recovered")
			syncSpawnedVegetationSoilState(str(child.name), "recovered")

			if debugLog:
				print("Recovered watered soil patch: ", child.name)


func regrowVegetationForDay(currentDay: int) -> void:
	var regrownClearedCount: int = regrowClearedVegetation(currentDay, maxDailyRegrowCount)

	if regrownClearedCount >= maxDailyRegrowCount:
		if debugLog:
			print("Daily cleared vegetation regrown: ", regrownClearedCount)
		return

	var remainingRegrowCount: int = maxDailyRegrowCount - regrownClearedCount
	
	var checkedCount: int = 0
	var chanceFailCount: int = 0
	var clearedCount: int = 0
	var grownAlreadyCount: int = 0
	var currentlySpawnedCount: int = 0
	var blockedCount: int = 0
	var spawnedCount: int = 0
	var candidateCells := getShuffledRegrowCells(currentDay)

	for worldCell in candidateCells:
		if spawnedCount >= remainingRegrowCount:
			printRegrowDebug(
				checkedCount,
				chanceFailCount,
				clearedCount,
				grownAlreadyCount,
				currentlySpawnedCount,
				blockedCount,
				spawnedCount + regrownClearedCount
			)
			return

		checkedCount += 1

		if shouldRegrowVegetationAtCell(worldCell, currentDay) == false:
			chanceFailCount += 1
			continue

		var vegetationId := "DeadGrassScatter_%d_%d" % [worldCell.x, worldCell.y]

		if isVegetationCleared(vegetationId):
			clearedCount += 1
			continue

		if grownVegetationIds.has(vegetationId):
			grownAlreadyCount += 1
			continue

		if isVegetationCurrentlySpawned(vegetationId):
			currentlySpawnedCount += 1
			continue

		var scatterPosition := vegetationCellToWorldCenter(worldCell) + getDeadGrassScatterOffset(worldCell)

		if isSpawnPositionBlocked(scatterPosition):
			blockedCount += 1
			continue

		if spawnDeadGrassScatterByCell(worldCell):
			grownVegetationIds.append(vegetationId)
			spawnedCount += 1

	printRegrowDebug(
		checkedCount,
		chanceFailCount,
		clearedCount,
		grownAlreadyCount,
		currentlySpawnedCount,
		blockedCount,
		spawnedCount + regrownClearedCount
	)


func printRegrowDebug(
	checkedCount: int,
	chanceFailCount: int,
	clearedCount: int,
	grownAlreadyCount: int,
	currentlySpawnedCount: int,
	blockedCount: int,
	spawnedCount: int
) -> void:
	if debugLog == false:
		return
	print(
		"Regrow debug | checked: ", checkedCount,
		" chanceFail: ", chanceFailCount,
		" cleared: ", clearedCount,
		" grownAlready: ", grownAlreadyCount,
		" currentlySpawned: ", currentlySpawnedCount,
		" blocked: ", blockedCount,
		" spawned: ", spawnedCount
	)

func regrowClearedVegetation(currentDay: int, maxCount: int) -> int:
	var successCount: int = 0
	var idsToTry: Array[String] = clearedVegetationIds.duplicate()

	for vegetationId in idsToTry:
		if successCount >= maxCount:
			break

		if canRegrowClearedVegetation(vegetationId, currentDay) == false:
			continue

		if getSpawnedVegetationSoilState(vegetationId, "dry") != "dry":
			continue

		var originalClearedDay: int = int(clearedVegetationDays.get(vegetationId, currentDay))

		clearedVegetationIds.erase(vegetationId)
		clearedVegetationDays.erase(vegetationId)
		grownVegetationIds.erase(vegetationId)

		var spawned: bool = spawnVegetationById(vegetationId)

		if debugLog:
			print("Regrow cleared result: ", vegetationId, " spawned: ", spawned)

		if spawned:
			if grownVegetationIds.has(vegetationId) == false:
				grownVegetationIds.append(vegetationId)

			successCount += 1
		else:
			if clearedVegetationIds.has(vegetationId) == false:
				clearedVegetationIds.append(vegetationId)

			clearedVegetationDays[vegetationId] = originalClearedDay

	return successCount


func shouldRegrowVegetationAtCell(cellPosition: Vector2i, currentDay: int) -> bool:
	var value: int = abs(int(hash(str(cellPosition) + "_regrow_day_" + str(currentDay)))) % 100
	return value < dailyRegrowChance


func isVegetationCurrentlySpawned(vegetationId: String) -> bool:
	if clearableObjectsRoot == null:
		return false

	var existing := clearableObjectsRoot.get_node_or_null(vegetationId)

	if existing == null:
		return false

	if existing.has_method("isCleared") and bool(existing.call("isCleared")):
		return false

	if existing is CanvasItem:
		return existing.visible

	return true


func getShuffledRegrowCells(currentDay: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = getVegetationCandidateCells()

	var rng := RandomNumberGenerator.new()
	rng.seed = int(currentDay * 92821 + 137)

	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp := cells[i]
		cells[i] = cells[j]
		cells[j] = temp

	return cells


func getWorldBoundsRect() -> Rect2:
	if boundsRoot == null:
		boundsRoot = get_node_or_null(boundsRootPath) as Node2D

	if boundsRoot == null:
		return Rect2()

	var result := Rect2()
	var hasRect := false

	var nodes: Array[Node] = [boundsRoot]

	while nodes.size() > 0:
		var node: Node = nodes.pop_back()

		for child in node.get_children():
			nodes.append(child)

		if node is CollisionShape2D:
			var collisionShape := node as CollisionShape2D
			var shape := collisionShape.shape

			if shape is RectangleShape2D:
				var rectShape := shape as RectangleShape2D
				var size := rectShape.size * collisionShape.global_scale.abs()
				var rect := Rect2(
					collisionShape.global_position - size / 2.0,
					size
				)

				if hasRect == false:
					result = rect
					hasRect = true
				else:
					result = result.merge(rect)

	if hasRect == false:
		return Rect2()

	return result


func getVegetationCandidateCells() -> Array[Vector2i]:
	if useWorldAreaSpawn:
		return buildWorldAreaCandidateCells()
	
	var result: Array[Vector2i] = []
	var worldRect: Rect2 = getWorldBoundsRect()

	if worldRect.size == Vector2.ZERO:
		return result

	var minCell: Vector2i = worldPositionToVegetationCell(worldRect.position)
	var maxCell: Vector2i = worldPositionToVegetationCell(worldRect.position + worldRect.size)

	for y in range(minCell.y, maxCell.y + 1):
		for x in range(minCell.x, maxCell.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			var center: Vector2 = vegetationCellToWorldCenter(cell)

			if worldRect.has_point(center):
				result.append(cell)

	return result


func worldPositionToVegetationCell(worldPosition: Vector2) -> Vector2i:
	return Vector2i(
		floori(worldPosition.x / float(cellSize)),
		floori(worldPosition.y / float(cellSize))
	)


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if terrainManager == null:
		terrainManager = get_tree().get_first_node_in_group("terrain_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func buildWorldAreaCandidateCells() -> Array[Vector2i]:
	refreshReferences()
	
	print("Vegetation spawn area ids at runtime: ", vegetationSpawnAreaIds)
	print("Vegetation exclude area ids at runtime: ", vegetationExcludeAreaIds)
	
	var result: Array[Vector2i] = []
	var usedCellKeys: Dictionary = {}
	
	if worldAreaManager == null:
		push_warning("VegetationSpawner: WorldAreaManager is null.")
		return result
	
	var step: int = max(1, worldAreaCandidateStep)
	
	for areaId in vegetationSpawnAreaIds:
		if not worldAreaManager.hasArea(areaId):
			push_warning("VegetationSpawner: unknown spawn areaId: " + areaId)
			continue
		
		var rect: Rect2i = worldAreaManager.getAreaRect(areaId)
		
		for y in range(rect.position.y, rect.position.y + rect.size.y, step):
			for x in range(rect.position.x, rect.position.x + rect.size.x, step):
				var cell: Vector2i = Vector2i(x, y)
				
				if not canUseCellForVegetation(cell):
					continue
				
				var key: String = "%d,%d" % [cell.x, cell.y]
				if usedCellKeys.has(key):
					continue
				
				usedCellKeys[key] = true
				result.append(cell)
	
	return result


func canUseCellForVegetation(cell: Vector2i) -> bool:
	#refreshReferences()
	
	if isCellInsideWalledGardenInterior(cell) == false:
		return false

	if worldAreaManager != null:
		for areaId in vegetationExcludeAreaIds:
			if worldAreaManager.hasArea(areaId) and worldAreaManager.isCellInArea(cell, areaId):
				return false
	
	if terrainManager != null:
		var data: Dictionary = terrainManager.getTerrainCell(cell)
		
		if bool(data.get("water", false)):
			return false
		
		if bool(data.get("blocked", false)):
			return false
		
		var terrainId: String = str(data.get("terrainId", ""))
		
		match terrainId:
			"water", "stone_ground", "rocky_ground":
				return false
	
	return true
