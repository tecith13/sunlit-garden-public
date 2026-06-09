extends StaticBody2D

@export var debugLog: bool = false

@export var cropId: String = "carrot"

# 당근 씨앗 1개 가격.
@export var carrotSeedPrice: int = 10

# 상호작용 가능 거리.
@export var interactDistance: float = 120.0

# 플레이어 참조.
@onready var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

# InventoryManager 참조.
var inventoryManager: Node = null
var cropDatabase: Node = null
var itemDatabase: Node = null


func _ready() -> void:
	add_to_group("shop")
	inventoryManager = get_tree().get_first_node_in_group("inventory_manager")
	cropDatabase = get_tree().get_first_node_in_group("crop_database")
	itemDatabase = get_tree().get_first_node_in_group("item_database")
	if debugLog: 
		print("Shop ready")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		tryBuySeed()


func refreshReferences() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if cropDatabase == null:
		cropDatabase = get_tree().get_first_node_in_group("crop_database")
		
	if itemDatabase == null:
		itemDatabase = get_tree().get_first_node_in_group("item_database")


func tryBuySeed() -> void:
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

	buySeed()


func canInteract() -> bool:
	var distanceToPlayer := global_position.distance_to(player.global_position)
	return distanceToPlayer <= interactDistance


func buySeed() -> void:
	var seedPrice: int = getSeedPrice(cropId)
	var seedItemId: String = getSeedItemId(cropId)

	var paid: bool = inventoryManager.spendMoney(seedPrice)

	if paid == false:
		showLocalizedFeedbackText("feedback.not_enough_money")
		if debugLog:
			print("Cannot buy ", seedItemId, ". Not enough money.")
		return

	inventoryManager.addItem(seedItemId, 1)
	
	var seedDisplayName := getItemDisplayName(seedItemId)
	showLocalizedFeedbackText("feedback.bought_item", [seedDisplayName])
	
	if debugLog:
		print("Bought ", seedItemId, " for: ", seedPrice)	


func getSeedPrice(targetCropId: String) -> int:
	refreshReferences()

	if cropDatabase != null and cropDatabase.has_method("getSeedPrice"):
		return cropDatabase.getSeedPrice(targetCropId)

	return carrotSeedPrice


func getSeedItemId(targetCropId: String) -> String:
	refreshReferences()

	if cropDatabase != null and cropDatabase.has_method("getSeedItemId"):
		return cropDatabase.getSeedItemId(targetCropId)

	return targetCropId + "_seed"


func showLocalizedFeedbackText(key: String, values: Array = []) -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("showLocalizedFeedbackText"):
		uiManager.showLocalizedFeedbackText(key, values)


func getItemDisplayName(itemId: String) -> String:
	refreshReferences()

	if itemDatabase == null:
		return itemId

	var localizationManager := get_tree().get_first_node_in_group("localization_manager")

	if itemDatabase.has_method("getDisplayNameKey"):
		var displayNameKey: String = itemDatabase.getDisplayNameKey(itemId)

		if displayNameKey != "" and localizationManager != null and localizationManager.has_method("trText"):
			return localizationManager.trText(displayNameKey)

	if itemDatabase.has_method("getDisplayName"):
		var displayName: String = itemDatabase.getDisplayName(itemId)
		return displayName

	return itemId
