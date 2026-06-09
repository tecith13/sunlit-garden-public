extends Node
class_name WorldLayoutBootstrap

@export var applyOnReady: bool = true
@export var printDebug: bool = true

@export var playerPath: NodePath
@export var playerHousePath: NodePath
@export var playerHouseBackgroundPath: NodePath
@export var playerHouseForegroundPath: NodePath
@export var playerHouseVisualOffset: Vector2 = Vector2(0, 96)
@export var autoPlacePlayerHouse: bool = false
@export var fieldAreaPath: NodePath
@export var shopPath: NodePath
@export var shippingBoxPath: NodePath

# 기존 Shop은 임시로 참새 씨앗 가판대 자리로 이동.
@export var shopAreaId: String = "seed_stall_area"

# 기존 ShippingBox는 테스트 편의를 위해 우편통 근처에 둔다.
# 나중에 crop trade/shipping system이 생기면 shipping_trade_area로 옮길 수 있음.
@export var shippingBoxAreaId: String = "shipping_trade_area"

# FieldArea는 초기 망가진 정원 / 농사 확장 구역 쪽.
@export var fieldAreaId: String = "ruined_garden_area"

# 플레이어 시작 위치는 집 앞쪽으로 약간 아래.
@export var playerSpawnOffsetCells: Vector2i = Vector2i(0, 18)

@export var fieldAreaOffsetCells: Vector2i = Vector2i(-35, -15)

@export var mailAccessObjectPath: NodePath
@export var mailAccessAreaId: String = "mailbox_area"
@export var mailAccessOffsetCells: Vector2i = Vector2i(-2, 0)
#@export var mailAccessAreaId: String = "player_home_area"
#@export var mailAccessOffsetCells: Vector2i = Vector2i(6, 18)

@export var playerHouseAreaId: String = "house_plot"
@export var playerHouseOffsetCells: Vector2i = Vector2i(0, 28)

var worldAreaManager: WorldAreaManager = null
var worldGrid: WorldGrid = null


func _ready() -> void:
	add_to_group("world_layout_bootstrap")
	refreshReferences()
	
	if applyOnReady:
		call_deferred("applyStarterObjectLayout")


func refreshReferences() -> void:
	if worldAreaManager == null:
		worldAreaManager = get_tree().get_first_node_in_group("world_area_manager")
	
	if worldGrid == null:
		worldGrid = get_tree().get_first_node_in_group("world_grid")


func applyStarterObjectLayout() -> void:
	refreshReferences()
	
	if worldAreaManager == null or worldGrid == null:
		push_warning("WorldLayoutBootstrap: missing WorldAreaManager or WorldGrid.")
		return
	
	if autoPlacePlayerHouse:
		placePlayerHouse()
	placeFieldArea()
	placeShop()
	placeShippingBox()
	placeMailAccessObject()
	placePlayer()
	
	if printDebug:
		print("WorldLayoutBootstrap applied starter object layout.")


func getNode2DOrNull(path: NodePath, fallbackGroupName: String = "") -> Node2D:
	var node: Node = null
	
	if path != NodePath():
		node = get_node_or_null(path)
	
	if node == null and fallbackGroupName != "":
		node = get_tree().get_first_node_in_group(fallbackGroupName)
	
	if node == null:
		return null
	
	if node is Node2D:
		return node as Node2D
	
	push_warning("Node is not Node2D: " + str(node.name))
	return null


func getAreaCenterWorld(areaId: String) -> Vector2:
	if not worldAreaManager.hasArea(areaId):
		push_warning("Unknown areaId for layout: " + areaId)
		return Vector2.ZERO
	
	return worldAreaManager.getAreaCenterWorld(areaId)


func getAreaCenterCell(areaId: String) -> Vector2i:
	if not worldAreaManager.hasArea(areaId):
		push_warning("Unknown areaId for layout: " + areaId)
		return Vector2i.ZERO
	
	return worldAreaManager.getAreaCenterCell(areaId)


#func placePlayerHouse() -> void:
	#var house := getNode2DOrNull(playerHousePath, "player_house")
	#if house == null:
		#push_warning("WorldLayoutBootstrap: PlayerHouse not found.")
		#return
	#
	#var target: Vector2 = getAreaCenterWorld("player_home_area")
	#house.global_position = target
	#
	#if printDebug:
		#print("Placed PlayerHouse at ", target)
func placePlayerHouse() -> void:
	var house := getNode2DOrNull(playerHousePath, "player_house")
	
	if house == null:
		house = findNode2DByName("PlayerHouse")
	
	if house == null:
		push_warning("WorldLayoutBootstrap: PlayerHouse not found.")
		return
	
	var centerCell: Vector2i = getAreaCenterCell(playerHouseAreaId)
	var targetCell: Vector2i = centerCell + playerHouseOffsetCells
	var target: Vector2 = worldGrid.cell_to_world_center(targetCell)
	
	house.global_position = target
	placePlayerHouseVisualLayer(playerHouseBackgroundPath, "PlayerHouseBackground", target)
	placePlayerHouseVisualLayer(playerHouseForegroundPath, "PlayerHouseForeground", target)
	
	if printDebug:
		print("Placed PlayerHouse at ", target, " area:", playerHouseAreaId, " cell:", targetCell)


func placePlayerHouseVisualLayer(path: NodePath, fallbackName: String, target: Vector2) -> void:
	var visualLayer := getNode2DOrNull(path)
	
	if visualLayer == null:
		visualLayer = findNode2DByName(fallbackName)
	
	if visualLayer == null:
		return
	
	visualLayer.global_position = target - playerHouseVisualOffset


func placeFieldArea() -> void:
	var fieldArea := getNode2DOrNull(fieldAreaPath, "field_area")
	
	if fieldArea == null:
		fieldArea = findNode2DByName("FieldArea")
	
	if fieldArea == null:
		push_warning("WorldLayoutBootstrap: FieldArea not found.")
		return
	
	var homeCenterCell: Vector2i = getAreaCenterCell("player_home_area")
	var fieldCell: Vector2i = homeCenterCell + fieldAreaOffsetCells
	var target: Vector2 = worldGrid.cell_to_world_center(fieldCell)
	
	fieldArea.global_position = target
	
	if printDebug:
		print("Placed FieldArea at ", target, " fieldCell:", fieldCell)


func placeShop() -> void:
	var shop := getNode2DOrNull(shopPath, "shop")
	
	if shop == null:
		shop = findNode2DByName("Shop")
	
	if shop == null:
		push_warning("WorldLayoutBootstrap: Shop not found.")
		return
	
	var target: Vector2 = getAreaCenterWorld(shopAreaId)
	shop.global_position = target
	
	if printDebug:
		print("Placed Shop at ", target, " area:", shopAreaId)


func placeShippingBox() -> void:
	var shippingBox := getNode2DOrNull(shippingBoxPath, "shipping_box")
	
	if shippingBox == null:
		shippingBox = findNode2DByName("ShippingBox")
	
	if shippingBox == null:
		push_warning("WorldLayoutBootstrap: ShippingBox not found.")
		return
	
	var target: Vector2 = getAreaCenterWorld(shippingBoxAreaId)
	target += Vector2(0, WorldGrid.CELL_SIZE * 2)
	
	shippingBox.global_position = target
	
	if printDebug:
		print("Placed ShippingBox at ", target, " area:", shippingBoxAreaId)


func placePlayer() -> void:
	var player := getNode2DOrNull(playerPath, "player")
	if player == null:
		push_warning("WorldLayoutBootstrap: Player not found.")
		return
	
	var homeCenterCell: Vector2i = getAreaCenterCell("player_home_area")
	var spawnCell: Vector2i = homeCenterCell + playerSpawnOffsetCells
	var target: Vector2 = worldGrid.cell_to_world_center(spawnCell)
	
	player.global_position = target
	
	if printDebug:
		print("Placed Player at ", target, " spawnCell:", spawnCell)


func findNode2DByName(targetName: String) -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null
	
	return findNode2DRecursive(root, targetName)


func findNode2DRecursive(node: Node, targetName: String) -> Node2D:
	if node.name == targetName and node is Node2D:
		return node as Node2D
	
	for child in node.get_children():
		var result := findNode2DRecursive(child, targetName)
		if result != null:
			return result
	
	return null


func placeMailAccessObject() -> void:
	var mailObject := getNode2DOrNull(mailAccessObjectPath, "mail_access_object")
	
	if mailObject == null:
		mailObject = findNode2DByName("MailAccessObject")
	
	if mailObject == null:
		push_warning("WorldLayoutBootstrap: MailAccessObject not found.")
		return
	
	var centerCell: Vector2i = getAreaCenterCell(mailAccessAreaId)
	var targetCell: Vector2i = centerCell + mailAccessOffsetCells
	var target: Vector2 = worldGrid.cell_to_world_center(targetCell)
	
	mailObject.global_position = target
	
	if printDebug:
		print("Placed MailAccessObject at ", target, " area:", mailAccessAreaId, " cell:", targetCell)
