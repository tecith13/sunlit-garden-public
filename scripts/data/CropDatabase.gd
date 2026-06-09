extends Node

const CROPS_JSON_PATH := "res://data/crops.json"

# 작물 데이터베이스.
# 이제 JSON 파일에서 로드함.
var crops: Dictionary = {}


func _ready() -> void:
	add_to_group("crop_database")
	loadCrops()
	print("CropDatabase ready")


func loadCrops() -> void:
	crops = loadJson(CROPS_JSON_PATH)

	if crops.is_empty():
		print("CropDatabase: crops data is empty.")
	else:
		print("CropDatabase: crops loaded: ", crops.keys())


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


func hasCrop(cropId: String) -> bool:
	return crops.has(cropId)


func getCropData(cropId: String) -> Dictionary:
	if crops.has(cropId) == false:
		print("Crop data not found: ", cropId)
		return {}

	return crops[cropId]


func getDisplayName(cropId: String) -> String:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return cropId

	if cropData.has("displayName") == false:
		return cropId

	return String(cropData["displayName"])


func getDisplayNameKey(cropId: String) -> String:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return "item." + cropId

	if cropData.has("displayNameKey") == false:
		return "item." + cropId

	return String(cropData["displayNameKey"])


func getSeedItemId(cropId: String) -> String:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return cropId + "_seed"

	if cropData.has("seedItemId") == false:
		return cropId + "_seed"

	return String(cropData["seedItemId"])


func getMaxGrowthStage(cropId: String) -> int:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return 3

	if cropData.has("maxGrowthStage") == false:
		return 3

	return int(cropData["maxGrowthStage"])


func getSeedPrice(cropId: String) -> int:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return 10

	if cropData.has("seedPrice") == false:
		return 10

	return int(cropData["seedPrice"])


func getSellPrice(cropId: String) -> int:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return 0

	if cropData.has("sellPrice") == false:
		return 0

	return int(cropData["sellPrice"])


func getCropStageTexture(cropId: String, growthStage: int) -> Texture2D:
	var cropData := getCropData(cropId)

	if cropData.is_empty():
		return null

	if cropData.has("stageSprites") == false:
		print("stageSprites not found: ", cropId)
		return null

	var stageSprites: Dictionary = cropData["stageSprites"]
	var stageKey := str(growthStage)

	if stageSprites.has(stageKey) == false:
		print("Stage sprite not found: ", cropId, " / ", growthStage)
		return null

	var texturePath := String(stageSprites[stageKey])

	if ResourceLoader.exists(texturePath) == false:
		print("Texture file does not exist: ", texturePath)
		return null

	return load(texturePath)
