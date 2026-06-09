extends Node

# 현재 날짜.
var currentDay: int = 1


func _ready() -> void:
	# 다른 스크립트에서 GameManager를 찾을 수 있게 그룹에 추가.
	add_to_group("game_manager")

	print("Day: ", currentDay)


func _input(event: InputEvent) -> void:
	# 테스트용 다음 날 입력.
	# 나중에는 침대/집 상호작용으로 대체 가능.
	if event.is_action_pressed("next_day"):
		goToNextDay()


func nextDay() -> void:
	goToNextDay()


func goToNextDay() -> void:
	currentDay += 1

	print("Next Day: ", currentDay)

	processFieldsNextDay()
	processVegetationNextDay()
	updateStatusUI()


func processFieldsNextDay() -> void:
	var fieldAreas := get_tree().get_nodes_in_group("field_area")

	for fieldArea in fieldAreas:
		if fieldArea.has_method("processNextDay"):
			fieldArea.processNextDay(currentDay)


func processVegetationNextDay() -> void:
	var vegetationSpawner := get_tree().get_first_node_in_group("vegetation_spawner")


	if vegetationSpawner != null and vegetationSpawner.has_method("processNextDay"):
		vegetationSpawner.processNextDay(currentDay)


func updateStatusUI() -> void:
	var uiManager := get_tree().get_first_node_in_group("ui_manager")

	if uiManager != null and uiManager.has_method("updateStatus"):
		uiManager.updateStatus()
