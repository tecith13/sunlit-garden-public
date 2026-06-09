extends Node
class_name TerrainManager

const DEFAULT_TERRAIN_ID: String = "grass"
const DEFAULT_HEIGHT: int = 0

var worldGrid: WorldGrid = null
var worldAreaManager: WorldAreaManager = null

var terrainCells: Dictionary = {}
var heightConnectors: Dictionary = {}

var debugBrookSampleWaterCell: Vector2i = Vector2i.ZERO

func _ready() -> void:
	add_to_group("terrain_manager")
	refreshReferences()
	print("TerrainManager ready.")
	call_deferred("applyStarterTerrainPreset")


func refreshReferences() -> void:
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")
	
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")


func getCellKey(cell: Vector2i) -> String:
	if worldGrid != null:
		return worldGrid.get_cell_key(cell)
	return "%d,%d" % [cell.x, cell.y]


func getDirectionBetween(fromCell: Vector2i, toCell: Vector2i) -> String:
	var delta := toCell - fromCell
	
	if delta == Vector2i(0, -1):
		return "N"
	if delta == Vector2i(0, 1):
		return "S"
	if delta == Vector2i(1, 0):
		return "E"
	if delta == Vector2i(-1, 0):
		return "W"
	
	return ""


func getOppositeDirection(direction: String) -> String:
	match direction:
		"N":
			return "S"
		"S":
			return "N"
		"E":
			return "W"
		"W":
			return "E"
		_:
			return ""


func getConnectorKey(cell: Vector2i, direction: String) -> String:
	return "%s|%s" % [getCellKey(cell), direction]


func makeDefaultCellData() -> Dictionary:
	return {
		"terrainId": DEFAULT_TERRAIN_ID,
		"height": DEFAULT_HEIGHT,
		"overlayId": "",
		"blocked": false,
		"water": false
	}


func hasTerrainCell(cell: Vector2i) -> bool:
	return terrainCells.has(getCellKey(cell))


func getTerrainCell(cell: Vector2i) -> Dictionary:
	var key := getCellKey(cell)
	
	if terrainCells.has(key):
		return terrainCells[key]
	
	return makeDefaultCellData()


func setTerrainCell(cell: Vector2i, data: Dictionary) -> void:
	var mergedData := makeDefaultCellData()
	
	for key in data.keys():
		mergedData[key] = data[key]
	
	terrainCells[getCellKey(cell)] = mergedData


func setTerrainId(cell: Vector2i, terrainId: String) -> void:
	var data := getTerrainCell(cell)
	data["terrainId"] = terrainId
	
	if terrainId == "water" or terrainId == "stream" or terrainId == "river":
		data["water"] = true
		data["blocked"] = true
	
	setTerrainCell(cell, data)


func setHeight(cell: Vector2i, height: int) -> void:
	var data := getTerrainCell(cell)
	data["height"] = height
	setTerrainCell(cell, data)


func setBlocked(cell: Vector2i, blocked: bool) -> void:
	var data := getTerrainCell(cell)
	data["blocked"] = blocked
	setTerrainCell(cell, data)


func setOverlay(cell: Vector2i, overlayId: String) -> void:
	var data := getTerrainCell(cell)
	data["overlayId"] = overlayId
	setTerrainCell(cell, data)


func isWater(cell: Vector2i) -> bool:
	var data := getTerrainCell(cell)
	return bool(data.get("water", false))


func isBlocked(cell: Vector2i) -> bool:
	var data := getTerrainCell(cell)
	return bool(data.get("blocked", false))


func getHeight(cell: Vector2i) -> int:
	var data := getTerrainCell(cell)
	return int(data.get("height", DEFAULT_HEIGHT))


func addHeightConnector(cell: Vector2i, direction: String, connectorId: String = "connector") -> void:
	if direction == "":
		return
	
	var targetCell := getNeighborCell(cell, direction)
	
	heightConnectors[getConnectorKey(cell, direction)] = {
		"connectorId": connectorId,
		"fromHeight": getHeight(cell),
		"toHeight": getHeight(targetCell)
	}
	
	var opposite := getOppositeDirection(direction)
	if opposite != "":
		heightConnectors[getConnectorKey(targetCell, opposite)] = {
			"connectorId": connectorId,
			"fromHeight": getHeight(targetCell),
			"toHeight": getHeight(cell)
		}


func hasHeightConnector(fromCell: Vector2i, toCell: Vector2i) -> bool:
	var direction := getDirectionBetween(fromCell, toCell)
	if direction == "":
		return false
	
	return heightConnectors.has(getConnectorKey(fromCell, direction))


func getNeighborCell(cell: Vector2i, direction: String) -> Vector2i:
	match direction:
		"N":
			return cell + Vector2i(0, -1)
		"S":
			return cell + Vector2i(0, 1)
		"E":
			return cell + Vector2i(1, 0)
		"W":
			return cell + Vector2i(-1, 0)
		_:
			return cell


func canMoveBetween(fromCell: Vector2i, toCell: Vector2i) -> bool:
	var delta := toCell - fromCell
	
	# 일단 상하좌우 1칸 이동만 판정.
	if abs(delta.x) + abs(delta.y) != 1:
		return false
	
	if isBlocked(toCell):
		return false
	
	if isWater(toCell):
		return false
	
	var fromHeight: int = getHeight(fromCell)
	var toHeight: int = getHeight(toCell)
	var heightDiff: int = abs(fromHeight - toHeight)
	
	if heightDiff == 0:
		return true
	
	if hasHeightConnector(fromCell, toCell):
		return true
	
	return false


func debugPrintCell(cell: Vector2i) -> void:
	var data := getTerrainCell(cell)
	print("Terrain cell ", cell, " data: ", data)


func debugBuildTestTerrain() -> void:
	# 테스트용. 실제 M2 지형 생성 전까지 좌표/높이/물 판정 확인용.
	setTerrainCell(Vector2i(0, 0), {
		"terrainId": "grass",
		"height": 0,
		"blocked": false,
		"water": false
	})
	
	setTerrainCell(Vector2i(1, 0), {
		"terrainId": "grass",
		"height": 1,
		"blocked": false,
		"water": false
	})
	
	setTerrainCell(Vector2i(2, 0), {
		"terrainId": "water",
		"height": -1,
		"blocked": true,
		"water": true
	})
	
	addHeightConnector(Vector2i(0, 0), "E", "stone_steps")
	
	print("Terrain test:")
	print("0,0 -> 1,0 canMove: ", canMoveBetween(Vector2i(0, 0), Vector2i(1, 0)))
	print("1,0 -> 2,0 canMove: ", canMoveBetween(Vector2i(1, 0), Vector2i(2, 0)))

func applyStarterTerrainPreset() -> void:
	refreshReferences()
	
	if worldAreaManager == null:
		push_warning("Cannot apply starter terrain preset. WorldAreaManager is null.")
		return
	
	terrainCells.clear()
	heightConnectors.clear()
	
	applyAreaTerrain("starter_region", "grass", 0, "", false, false)
	
	applyAreaTerrain("player_home_area", "grass", 0, "", false, false)
	applyAreaTerrain("house_plot", "grass", 0, "", false, false)
	
	applyAreaTerrain("ruined_garden_area", "dry_grass", 0, "", false, false)
	applyAreaTerrain("west_field_expansion_area", "dry_grass", 0, "", false, false)
	
	applyAreaTerrain("back_forest_area", "forest_floor", 0, "", false, false)
	applyAreaTerrain("blocked_old_path_area", "forest_path_blocked", 1, "", true, false)
	applyAreaTerrain("archive_route_area", "forest_floor", 1, "", false, false)
	
	applyAreaTerrain("old_stone_road_area", "grass", 0, "old_stone_path", false, false)
	
	applyAreaTerrain("village_square_area", "stone_ground", 1, "old_square_stone", false, false)
	applyAreaTerrain("seed_stall_area", "stone_ground", 1, "old_square_stone", false, false)
	applyAreaTerrain("shipping_trade_area", "stone_ground", 1, "old_square_stone", false, false)
	applyAreaTerrain("furniture_workshop_area", "stone_ground", 1, "old_square_stone", false, false)
	applyAreaTerrain("temporary_housing_area", "grass", 1, "village_lot", false, false)
	applyAreaTerrain("teahouse_area", "grass", 1, "village_lot", false, false)
	applyAreaTerrain("external_road_area", "dirt", 1, "old_road", false, false)
	
	# brook_area 전체는 개울 후보 지형으로 먼저 깐다.
	applyAreaTerrain("brook_area", "riverbank", 0, "", false, false)
	applyAreaTerrain("mineral_fragment_area", "rocky_ground", 0, "", false, false)
	applyAreaTerrain("east_gathering_area", "wild_grass", 0, "", false, false)

	# 실제 물길은 brook_area 안에서 곡선 형태로 별도 생성한다.
	generateStarterBrook()
	
	buildStarterHeightConnectors()
	
	print("Starter terrain preset applied.")
	debugPrintStarterTerrainSummary()


func applyAreaTerrain(
	areaId: String,
	terrainId: String,
	height: int,
	overlayId: String = "",
	blocked: bool = false,
	water: bool = false
) -> void:
	if worldAreaManager == null:
		return
	
	if not worldAreaManager.hasArea(areaId):
		push_warning("Cannot apply terrain. Unknown areaId: " + areaId)
		return
	
	var cells: Array[Vector2i] = worldAreaManager.getAreaCellList(areaId)
	
	for cell in cells:
		setTerrainCell(cell, {
			"terrainId": terrainId,
			"height": height,
			"overlayId": overlayId,
			"blocked": blocked,
			"water": water
		})


func buildStarterHeightConnectors() -> void:
	if worldAreaManager == null:
		return
	
	var roadCenter: Vector2i = worldAreaManager.getAreaCenterCell("old_stone_road_area")
	
	# 정원 height 0 → 마을터 height 1로 올라가는 임시 계단 후보.
	var lowerCell: Vector2i = roadCenter + Vector2i(0, 20)
	var upperCell: Vector2i = lowerCell + Vector2i(0, -1)
	
	setTerrainCell(lowerCell, {
		"terrainId": "grass",
		"height": 0,
		"overlayId": "stone_steps",
		"blocked": false,
		"water": false
	})
	
	setTerrainCell(upperCell, {
		"terrainId": "stone_ground",
		"height": 1,
		"overlayId": "stone_steps",
		"blocked": false,
		"water": false
	})
	
	addHeightConnector(lowerCell, "N", "stone_steps")


func debugPrintStarterTerrainSummary() -> void:
	if worldAreaManager == null:
		return
	
	print("Starter terrain summary:")
	
	var sampleAreas: Array[String] = [
		"player_home_area",
		"back_forest_area",
		"blocked_old_path_area",
		"old_stone_road_area",
		"village_square_area",
		"brook_area",
		"mineral_fragment_area"
	]
	
	for areaId in sampleAreas:
		var centerCell: Vector2i = worldAreaManager.getAreaCenterCell(areaId)
		var data: Dictionary = getTerrainCell(centerCell)
		print("- ", areaId, " center:", centerCell, " data:", data)
		
	var brookSampleData: Dictionary = getTerrainCell(debugBrookSampleWaterCell)
	print("- brook_sample_water_cell:", debugBrookSampleWaterCell, " data:", brookSampleData)


func parseCellKey(key: String) -> Vector2i:
	if worldGrid != null:
		return worldGrid.parse_vector2i_key(key)
	
	var parts := key.split(",")
	if parts.size() != 2:
		push_warning("Invalid cell key: " + key)
		return Vector2i.ZERO
	
	return Vector2i(int(parts[0]), int(parts[1]))


func generateStarterBrook() -> void:
	refreshReferences()
	
	if worldAreaManager == null:
		return
	
	if not worldAreaManager.hasArea("brook_area"):
		return
	
	var brookRect: Rect2i = worldAreaManager.getAreaRect("brook_area")
	var centerX: int = brookRect.position.x + floori(brookRect.size.x * 0.5)
	var startY: int = brookRect.position.y
	var endY: int = brookRect.position.y + brookRect.size.y
	var hasSample: bool = false
	
	for y in range(startY, endY):
		var localY: int = y - startY
		
		var waveA: float = sin(float(localY) * 0.12) * 8.0
		var waveB: float = sin(float(localY) * 0.035 + 1.7) * 10.0
		var streamCenterX: int = centerX + int(round(waveA + waveB))
		
		var width: int = 5
		if localY % 37 < 12:
			width = 6
		if localY % 61 < 8:
			width = 7
		
		paintBrookRow(streamCenterX, y, width)
		
		if not hasSample:
			debugBrookSampleWaterCell = Vector2i(streamCenterX, y)
			hasSample = true
	
	print("Starter brook generated. Sample water cell: ", debugBrookSampleWaterCell)


func paintBrookRow(centerX: int, y: int, width: int) -> void:
	var halfWidth: int = floori(width * 0.5)
	
	for offsetX in range(-halfWidth - 2, halfWidth + 3):
		var cell: Vector2i = Vector2i(centerX + offsetX, y)
		var distanceFromCenter: int = abs(offsetX)
		
		if distanceFromCenter <= halfWidth:
			setTerrainCell(cell, {
				"terrainId": "water",
				"height": -1,
				"overlayId": "",
				"blocked": true,
				"water": true
			})
		elif distanceFromCenter == halfWidth + 1:
			setTerrainCell(cell, {
				"terrainId": "wet_grass",
				"height": 0,
				"overlayId": "water_edge",
				"blocked": false,
				"water": false
			})
		else:
			# 바깥쪽은 강변 돌/풀 느낌.
			# 기존 rocky_ground나 다른 특수 지형을 무조건 덮지 않도록,
			# 기본 grass/riverbank 계열일 때만 바꾼다.
			var existingData: Dictionary = getTerrainCell(cell)
			var existingTerrainId: String = str(existingData.get("terrainId", ""))
			
			if existingTerrainId == "grass" or existingTerrainId == "riverbank" or existingTerrainId == "wild_grass":
				setTerrainCell(cell, {
					"terrainId": "riverbank",
					"height": 0,
					"overlayId": "",
					"blocked": false,
					"water": false
				})
