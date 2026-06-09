extends Node

const ITEMS_JSON_PATH := "res://data/items.json"

var items: Dictionary = {}


func _ready() -> void:
	add_to_group("item_database")
	loadItems()
	print("ItemDatabase ready")


func loadItems() -> void:
	items = loadJson(ITEMS_JSON_PATH)

	if items.is_empty():
		print("ItemDatabase: items data is empty.")
	else:
		print("ItemDatabase: items loaded: ", items.keys())


func loadJson(path: String) -> Dictionary:
	if FileAccess.file_exists(path) == false:
		print("JSON file not found: ", path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		print("Failed to open JSON file: ", path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("JSON parse failed or root is not Dictionary: ", path)
		return {}

	return parsed


func hasItemData(itemId: String) -> bool:
	return items.has(itemId)


func getItemData(itemId: String) -> Dictionary:
	if items.has(itemId) == false:
		return {}

	return items[itemId]


func getDisplayName(itemId: String) -> String:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return itemId

	if itemData.has("displayName") == false:
		return itemId

	return String(itemData["displayName"])


func getDisplayNameKey(itemId: String) -> String:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return ""

	if itemData.has("displayNameKey") == false:
		return ""

	return String(itemData["displayNameKey"])


func getCategory(itemId: String) -> String:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return ""

	if itemData.has("category") == false:
		return ""

	return String(itemData["category"])


func getIconPath(itemId: String) -> String:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return ""

	if itemData.has("icon") == false:
		return ""

	return String(itemData["icon"])


func getIconTexture(itemId: String) -> Texture2D:
	var iconPath := getIconPath(itemId)

	if iconPath == "":
		return null

	if ResourceLoader.exists(iconPath) == false:
		print("Item icon does not exist: ", iconPath)
		return null

	return load(iconPath)


func getStackLimit(itemId: String) -> int:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return 99

	if itemData.has("stackLimit") == false:
		return 99

	return int(itemData["stackLimit"])


func getBuyPrice(itemId: String) -> int:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return 0

	if itemData.has("buyPrice") == false:
		return 0

	return int(itemData["buyPrice"])


func getSellPrice(itemId: String) -> int:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return 0

	if itemData.has("sellPrice") == false:
		return 0

	return int(itemData["sellPrice"])


func getCropId(itemId: String) -> String:
	var itemData := getItemData(itemId)

	if itemData.is_empty():
		return ""

	if itemData.has("cropId") == false:
		return ""

	return String(itemData["cropId"])
