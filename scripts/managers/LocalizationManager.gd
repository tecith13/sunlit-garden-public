extends Node

const LOCALIZATION_DIR := "res://data/localization/"

var currentLanguage: String = "ko"
var texts: Dictionary = {}


func _ready() -> void:
	add_to_group("localization_manager")
	loadLanguage(currentLanguage)
	print("LocalizationManager ready")


func loadLanguage(languageCode: String) -> void:
	currentLanguage = languageCode

	var path := LOCALIZATION_DIR + languageCode + ".json"
	texts = loadJson(path)

	if texts.is_empty():
		print("LocalizationManager: language data is empty: ", languageCode)
	else:
		print("LocalizationManager: language loaded: ", languageCode, " / keys: ", texts.size())


func loadJson(path: String) -> Dictionary:
	if FileAccess.file_exists(path) == false:
		print("Localization JSON file not found: ", path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)

	if file == null:
		print("Failed to open localization JSON file: ", path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("Localization JSON parse failed or root is not Dictionary: ", path)
		return {}

	return parsed


func trText(key: String) -> String:
	if texts.has(key):
		return String(texts[key])

	print("Localization key not found: ", key)
	return key


func setLanguage(languageCode: String) -> void:
	if currentLanguage == languageCode:
		return

	loadLanguage(languageCode)


func getCurrentLanguage() -> String:
	return currentLanguage
