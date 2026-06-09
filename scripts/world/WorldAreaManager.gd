extends Node
class_name WorldAreaManager

var worldGrid: WorldGrid = null

# 새 맵 제작 기준점.
# 현재는 임시로 (0, 0)을 플레이어 집 중심으로 둔다.
# 나중에 실제 새 맵에서 PlayerHouse/HouseOrigin Marker 기준으로 바꿀 수 있음.
@export var playerHouseCenterCell: Vector2i = Vector2i.ZERO

# 전부 cell 기준 Rect.
var starterRegionRect: Rect2i

var playerHomeAreaRect: Rect2i
var startDeadGrassAreaRect: Rect2i
var walledGardenInteriorRect: Rect2i
var housePlotRect: Rect2i
var ruinedGardenAreaRect: Rect2i
var westFieldExpansionAreaRect: Rect2i

var mailboxAreaRect: Rect2i
var backForestAreaRect: Rect2i
var blockedOldPathAreaRect: Rect2i
var archiveRouteAreaRect: Rect2i

var oldStoneRoadAreaRect: Rect2i
var villageSquareAreaRect: Rect2i
var seedStallAreaRect: Rect2i
var shippingTradeAreaRect: Rect2i
var furnitureWorkshopAreaRect: Rect2i
var temporaryHousingAreaRect: Rect2i
var teahouseAreaRect: Rect2i
var externalRoadAreaRect: Rect2i

var brookAreaRect: Rect2i
var mineralFragmentAreaRect: Rect2i
var eastGatheringAreaRect: Rect2i


func _ready() -> void:
	add_to_group("world_area_manager")
	refreshReferences()
	buildDefaultAreas()
	print("WorldAreaManager ready.")
	debugPrintAreas()


func refreshReferences() -> void:
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func makeCenteredRect(centerCell: Vector2i, size: Vector2i) -> Rect2i:
	return Rect2i(
		centerCell - Vector2i(
			floori(size.x * 0.5),
			floori(size.y * 0.5)
		),
		size
	)


func buildDefaultAreas() -> void:
	# 전체 시작 지역.
	# 북쪽 숲/장서관 후보, 중앙 고립 정원, 남동쪽 마을터, 동쪽 개울까지 포함.
	starterRegionRect = Rect2i(
		playerHouseCenterCell + Vector2i(-224, -224),
		Vector2i(448, 448)
	)

	# 1. 플레이어 집 / 고립된 정원 중심부.
	playerHomeAreaRect = makeCenteredRect(
		playerHouseCenterCell,
		Vector2i(96, 80)
	)

	# DeadGrass-only spawn area. Keep player_home_area broad for terrain/layout,
	# but stop clearable dry grass before the raised south wall around y=443.
	startDeadGrassAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(-48, -40),
		Vector2i(96, 66)
	)

	# DeadGrass final filter area based on the current enclosed garden boundary:
	# west/east basalt walls around x=-590/590, south wall around y=443,
	# and the north forest boundary around y=-420.
	walledGardenInteriorRect = Rect2i(
		playerHouseCenterCell + Vector2i(-34, -14),
		Vector2i(68, 50)
	)

	# 집 건축 가능 부지.
	# 바닥/벽/문/가구 설치 및 확장 가능한 영역.
	housePlotRect = makeCenteredRect(
		playerHouseCenterCell + Vector2i(0, 12),
		Vector2i(128, 112)
	)

	# 2. 망가진 정원.
	# 집 서쪽/남서쪽의 초기 정리/농사 확장 구역.
	ruinedGardenAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(-112, 16),
		Vector2i(96, 88)
	)

	# 9. 서쪽 들판 / 농지 확장 구역.
	westFieldExpansionAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(-192, 40),
		Vector2i(144, 120)
	)

	# 3. 우편통.
	# 플레이어 집/정원과 낡은 돌길 사이의 첫 연결점.
	mailboxAreaRect = makeCenteredRect(
		playerHouseCenterCell + Vector2i(28, 38),
		Vector2i(24, 24)
	)

	# 4. 집 뒤 숲.
	# 집 북쪽. 자연 경계이자 후방 확장 방향.
	backForestAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(-96, -120),
		Vector2i(192, 88)
	)

	# 5. 막힌 옛길.
	# 집 뒤 숲에서 장서관/숲 기록소로 이어지는 막힌 경로.
	blockedOldPathAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(16, -176),
		Vector2i(56, 72)
	)

	# 6. 장서관 / 숲 기록소 후보.
	# M2에서는 자리만. 기능은 장기.
	archiveRouteAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(48, -224),
		Vector2i(72, 56)
	)

	# 집에서 마을터로 내려가는 낡은 돌길.
	oldStoneRoadAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(24, 56),
		Vector2i(48, 144)
	)

	# 11. 빈 광장 / 마을터.
	# 플레이어 정원과 떨어진 남동쪽 목적지.
	villageSquareAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(56, 184),
		Vector2i(128, 96)
	)

	# 12. 참새 씨앗 가판대 후보.
	# 처음에는 임시 가판대, 이후 씨앗 상점.
	seedStallAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(96, 144),
		Vector2i(48, 40)
	)

	# 14/15. 배송/출하/작물 거래 처리.
	# 외부 길과 마을 사이 물류 위치.
	shippingTradeAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(24, 216),
		Vector2i(64, 48)
	)

	# 13. 가구 공방 후보.
	# 초기에는 공방이 아니라 낡은 작업장터/예정지로 취급.
	furnitureWorkshopAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(0, 160),
		Vector2i(56, 48)
	)

	# 16. 빈집 / 임시 체류자 구역.
	temporaryHousingAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(160, 176),
		Vector2i(80, 72)
	)

	# 17. 찻집 후보.
	# 외부 길 근처. 복구된 길을 따라 돌아오는 NPC와 연결.
	teahouseAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(128, 256),
		Vector2i(80, 64)
	)

	# 18. 외부로 이어지는 길.
	externalRoadAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(72, 288),
		Vector2i(64, 96)
	)

	# 7. 개울가.
	# 동쪽 자연 경계 / 낮은 지대.
	brookAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(144, -40),
		Vector2i(96, 240)
	)

	# 8. 광물 조각 발견 지점.
	# 개울 북동쪽 바위 지대. 물 셀과 직접 겹치지 않게 배치.
	mineralFragmentAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(248, -72),
		Vector2i(48, 64)
	)

	# 19. 동쪽 자연 채집 구역.
	# 개울 자체가 아니라 개울 동쪽/남동쪽 주변 지형.
	eastGatheringAreaRect = Rect2i(
		playerHouseCenterCell + Vector2i(240, 32),
		Vector2i(96, 128)
	)


func getAreaRect(areaId: String) -> Rect2i:
	match areaId:
		"starter_region":
			return starterRegionRect
		"player_home_area":
			return playerHomeAreaRect
		"start_dead_grass_area":
			return startDeadGrassAreaRect
		"walled_garden_interior_area":
			return walledGardenInteriorRect
		"house_plot":
			return housePlotRect
		"ruined_garden_area":
			return ruinedGardenAreaRect
		"west_field_expansion_area":
			return westFieldExpansionAreaRect
		"mailbox_area":
			return mailboxAreaRect
		"back_forest_area":
			return backForestAreaRect
		"blocked_old_path_area":
			return blockedOldPathAreaRect
		"archive_route_area":
			return archiveRouteAreaRect
		"old_stone_road_area":
			return oldStoneRoadAreaRect
		"village_square_area":
			return villageSquareAreaRect
		"seed_stall_area":
			return seedStallAreaRect
		"shipping_trade_area":
			return shippingTradeAreaRect
		"furniture_workshop_area":
			return furnitureWorkshopAreaRect
		"temporary_housing_area":
			return temporaryHousingAreaRect
		"teahouse_area":
			return teahouseAreaRect
		"external_road_area":
			return externalRoadAreaRect
		"brook_area":
			return brookAreaRect
		"mineral_fragment_area":
			return mineralFragmentAreaRect
		"east_gathering_area":
			return eastGatheringAreaRect
		_:
			push_warning("Unknown areaId: " + areaId)
			return Rect2i()


func hasArea(areaId: String) -> bool:
	return getAreaIds().has(areaId)


func isCellInArea(cell: Vector2i, areaId: String) -> bool:
	if not hasArea(areaId):
		return false
	
	return getAreaRect(areaId).has_point(cell)


func isWorldPositionInArea(worldPosition: Vector2, areaId: String) -> bool:
	refreshReferences()
	
	if worldGrid == null:
		return false
	
	var cell: Vector2i = worldGrid.world_to_cell(worldPosition)
	return isCellInArea(cell, areaId)


func getAreaCenterCell(areaId: String) -> Vector2i:
	var rect: Rect2i = getAreaRect(areaId)
	return rect.position + Vector2i(
		floori(rect.size.x * 0.5),
		floori(rect.size.y * 0.5)
	)


func getAreaCenterWorld(areaId: String) -> Vector2:
	refreshReferences()
	
	if worldGrid == null:
		return Vector2.ZERO
	
	return worldGrid.cell_to_world_center(getAreaCenterCell(areaId))


func getAreaWorldRect(areaId: String) -> Rect2:
	refreshReferences()
	
	var rect: Rect2i = getAreaRect(areaId)
	
	if worldGrid == null:
		return Rect2()
	
	var worldPosition: Vector2 = worldGrid.cell_to_world(rect.position)
	var worldSize: Vector2 = Vector2(
		rect.size.x * WorldGrid.CELL_SIZE,
		rect.size.y * WorldGrid.CELL_SIZE
	)
	
	return Rect2(worldPosition, worldSize)


func getAreaCellList(areaId: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	if not hasArea(areaId):
		return result
	
	var rect: Rect2i = getAreaRect(areaId)
	
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			result.append(Vector2i(x, y))
	
	return result


func getAreaIds() -> Array[String]:
	return [
		"starter_region",
		"player_home_area",
		"start_dead_grass_area",
		"walled_garden_interior_area",
		"house_plot",
		"ruined_garden_area",
		"west_field_expansion_area",
		"mailbox_area",
		"back_forest_area",
		"blocked_old_path_area",
		"archive_route_area",
		"old_stone_road_area",
		"village_square_area",
		"seed_stall_area",
		"shipping_trade_area",
		"furniture_workshop_area",
		"temporary_housing_area",
		"teahouse_area",
		"external_road_area",
		"brook_area",
		"mineral_fragment_area",
		"east_gathering_area"
	]


func debugPrintAreas() -> void:
	print("World areas:")
	print("- playerHouseCenterCell: ", playerHouseCenterCell)
	for areaId in getAreaIds():
		var rect: Rect2i = getAreaRect(areaId)
		print("- ", areaId, " pos:", rect.position, " size:", rect.size)
