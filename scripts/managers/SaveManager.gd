extends Node

const SAVE_PATH: String = "user://sunlit_garden_save.json"

var gameManager: Node = null
var inventoryManager: Node = null


func _ready() -> void:
	add_to_group("save_manager")

	gameManager = get_tree().get_first_node_in_group("game_manager")
	inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	print("SaveManager ready")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		saveGame()

	if event.is_action_pressed("load_game"):
		loadGame()


func saveGame() -> void:
	refreshReferences()

	if gameManager == null:
		return

	if inventoryManager == null:
		return

	var saveData := {
		"currentDay": gameManager.currentDay,
		"money": inventoryManager.getMoney(),
		"items": inventoryManager.getAllItems(),
		"fields": getFieldSaveData(),
		"vegetation": getVegetationSaveData(),
		"mailAccessObjects": getMailAccessSaveData()
	}

	var jsonText := JSON.stringify(saveData, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("Save failed: could not open file.")
		return

	file.store_string(jsonText)
	file.close()

	print("Game saved: ", SAVE_PATH)


func loadGame() -> void:
	refreshReferences()

	if FileAccess.file_exists(SAVE_PATH) == false:
		print("Load failed: save file does not exist.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		print("Load failed: could not open file.")
		return

	var jsonText := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(jsonText)

	if parsed == null:
		print("Load failed: invalid JSON.")
		return

	applySaveData(parsed)

	print("Game loaded: ", SAVE_PATH)


func refreshReferences() -> void:
	if gameManager == null:
		gameManager = get_tree().get_first_node_in_group("game_manager")

	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")


func getFieldSaveData() -> Array:
	var fieldSaveList: Array = []
	var fieldAreas := get_tree().get_nodes_in_group("field_area")

	for fieldArea in fieldAreas:
		if fieldArea.has_method("getSaveData"):
			fieldSaveList.append(fieldArea.getSaveData())

	return fieldSaveList


func applySaveData(saveData: Dictionary) -> void:
	if gameManager != null and saveData.has("currentDay"):
		gameManager.currentDay = int(saveData["currentDay"])
		print("Loaded day: ", gameManager.currentDay)

	if inventoryManager != null:
		if saveData.has("money"):
			inventoryManager.setMoney(int(saveData["money"]))

		if saveData.has("items"):
			inventoryManager.setAllItems(saveData["items"])

	if saveData.has("fields"):
		var fieldAreas := get_tree().get_nodes_in_group("field_area")
		var fieldSaveList: Array = saveData["fields"]

		for i in range(min(fieldAreas.size(), fieldSaveList.size())):
			var fieldArea = fieldAreas[i]

			if fieldArea.has_method("loadSaveData"):
				fieldArea.loadSaveData(fieldSaveList[i])

	if saveData.has("vegetation"):
		applyVegetationSaveData(saveData["vegetation"])
	else:
		startNewVegetationIfPossible()
		
	if saveData.has("mailAccessObjects"):
		applyMailAccessSaveData(saveData["mailAccessObjects"])


func startNewVegetationIfPossible() -> void:
	var vegetationSpawner := get_tree().get_first_node_in_group("vegetation_spawner")

	if vegetationSpawner != null and vegetationSpawner.has_method("startNewVegetation"):
		vegetationSpawner.startNewVegetation()


func getVegetationSaveData() -> Dictionary:
	var vegetationSpawner := get_tree().get_first_node_in_group("vegetation_spawner")

	if vegetationSpawner != null and vegetationSpawner.has_method("getSaveData"):
		return vegetationSpawner.getSaveData()

	return {}


func applyVegetationSaveData(vegetationSaveData: Dictionary) -> void:
	var vegetationSpawner := get_tree().get_first_node_in_group("vegetation_spawner")

	if vegetationSpawner != null and vegetationSpawner.has_method("loadSaveData"):
		vegetationSpawner.loadSaveData(vegetationSaveData)


func getMailAccessSaveData() -> Array:
	var result: Array = []
	var mailObjects := get_tree().get_nodes_in_group("mail_access_object")
	
	for mailObject in mailObjects:
		if mailObject != null and mailObject.has_method("getSaveData"):
			result.append(mailObject.getSaveData())
	
	return result


func applyMailAccessSaveData(mailAccessSaveData: Array) -> void:
	var mailObjects := get_tree().get_nodes_in_group("mail_access_object")
	var objectsById: Dictionary = {}
	
	for mailObject in mailObjects:
		if mailObject == null:
			continue
		
		if "mailAccessId" in mailObject:
			objectsById[mailObject.mailAccessId] = mailObject
	
	for data in mailAccessSaveData:
		if not data is Dictionary:
			continue
		
		var mailAccessId: String = str(data.get("mailAccessId", ""))
		
		if mailAccessId == "":
			continue
		
		if not objectsById.has(mailAccessId):
			push_warning("MailAccessObject not found for save id: " + mailAccessId)
			continue
		
		var targetObject = objectsById[mailAccessId]
		
		if targetObject.has_method("loadSaveData"):
			targetObject.loadSaveData(data)
