extends StaticBody2D

@export var debugLog: bool = false

@export var cropId: String = "carrot"

# 당근 1개 판매 가격.
@export var carrotSellPrice: int = 20

# 상호작용 가능 거리.
# 플레이어 위치와 출하 상자 위치 사이 거리가 이 값 이하일 때만 판매 가능.
@export var interactDistance: float = 80.0

# 플레이어 참조.
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

# InventoryManager 참조.
var inventoryManager: Node = null
var cropDatabase: Node = null

func _ready() -> void:
	add_to_group("shipping_box")
	inventoryManager = get_tree().get_first_node_in_group("inventory_manager")
	cropDatabase = get_tree().get_first_node_in_group("crop_database")
	if debugLog:
		print("ShippingBox ready")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		trySellCrops()


func refreshReferences() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if cropDatabase == null:
		cropDatabase = get_tree().get_first_node_in_group("crop_database")


func trySellCrops() -> void:
	refreshReferences()

	if player == null:
		if debugLog:
			print("Player not found.")
		return

	if inventoryManager == null:
		if debugLog:
			print("InventoryManager not found.")
		return

	if canInteract() == false:
		return

	sellAllCrops()



func canInteract() -> bool:
	var distanceToPlayer := global_position.distance_to(player.global_position)
	return distanceToPlayer <= interactDistance


func sellAllCrops() -> void:
	var cropCount: int = inventoryManager.getItemCount(cropId)
	var cropDisplayName := getCropDisplayName(cropId)

	if cropCount <= 0:
		showLocalizedFeedbackText("feedback.no_crop_to_sell", [cropDisplayName])
		if debugLog:
			print("No crop to sell: ", cropId)
		return

	var sellPrice: int = getSellPrice(cropId)
	var totalPrice: int = cropCount * sellPrice

	var removed: bool = inventoryManager.removeItem(cropId, cropCount)

	if removed == false:
		if debugLog:
			print("Failed to remove carrots.")
		return

	inventoryManager.addMoney(totalPrice)

	showLocalizedFeedbackText("feedback.sold_money", [totalPrice])

	if debugLog:
		print("Sold crop: ", cropId, " Count: ", cropCount, " Earned: ", totalPrice)


func getSellPrice(cropId: String) -> int:
	refreshReferences()

	if cropDatabase != null and cropDatabase.has_method("getSellPrice"):
		return cropDatabase.getSellPrice(cropId)

	return carrotSellPrice


func showLocalizedFeedbackText(key: String, values: Array = []) -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("showLocalizedFeedbackText"):
		uiManager.showLocalizedFeedbackText(key, values)


func getCropDisplayName(targetCropId: String) -> String:
	refreshReferences()

	if cropDatabase == null:
		return targetCropId

	var localizationManager := get_tree().get_first_node_in_group("localization_manager")

	if cropDatabase.has_method("getDisplayNameKey"):
		var displayNameKey: String = cropDatabase.getDisplayNameKey(targetCropId)

		if displayNameKey != "" and localizationManager != null and localizationManager.has_method("trText"):
			return localizationManager.trText(displayNameKey)

	if cropDatabase.has_method("getDisplayName"):
		return cropDatabase.getDisplayName(targetCropId)

	return targetCropId
