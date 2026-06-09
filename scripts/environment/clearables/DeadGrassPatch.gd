extends Area2D

@export var interactDistance: float = 48.0
@export var shakeDistance: float = 4.0
@export var shakeDuration: float = 0.12
@export var returnDuration: float = 0.25
@export var waterDistance: float = 72.0
@export var waterTargetRadius: float = 40.0
@export var debugLog: bool = false
@export var revealFieldDryDirtOnClear: bool = false
@export var idleWindEnabled: bool = true
@export var idleWindAmplitudeDegrees: float = 1.15
@export var idleWindSpeed: float = 0.8
@export var idleWindUpdateInterval: float = 0.1
@export var idleWindMaxPivotCount: int = 0

@onready var visualRoot: Node2D = $VisualRoot
@onready var soilPatchSprite: Sprite2D = get_node_or_null("SoilPatchSprite") as Sprite2D
@onready var recoverySprite: Sprite2D = get_node_or_null("RecoverySprite") as Sprite2D

var player: Node2D = null
var toolManager: Node = null
var fieldArea: Node = null
var vegetationSpawner: Node = null
var cleared: bool = false
var soilState: String = "dry"
#var originalPosition: Vector2
#var shakeTween: Tween = null
var grassOriginalPositions: Dictionary = {}
var grassOriginalRotations: Dictionary = {}
var grassTweens: Dictionary = {}
var idleWindBasePhase: float = 0.0
var idleWindUpdateTimer: float = 0.0
var touchShakeUntilTime: float = 0.0


@export var dropEnabled: bool = true
@export var dropTable: Array[Dictionary] = [
	{
		"itemId": "carrot_seed",
		"chance": 0.25,
		"amountMin": 1,
		"amountMax": 1
	},
	{
		"itemId": "carrot_seed",
		"chance": 0.05,
		"amountMin": 2,
		"amountMax": 2
	}
]
@export var seedDropAmountMin: int = 1
@export var seedDropAmountMax: int = 1

static var lastClearFrame: int = -1


func _ready() -> void:
	add_to_group("clearable_object")
	add_to_group("waterable_soil_patch")

	player = get_tree().get_first_node_in_group("player") as Node2D
	toolManager = get_tree().get_first_node_in_group("tool_manager")
	fieldArea = get_tree().get_first_node_in_group("field_area")
	vegetationSpawner = get_tree().get_first_node_in_group("vegetation_spawner")
	
	#storeGrassOriginalPositions()
	storeGrassOriginalTransforms()
	applySoilStateVisual()
	idleWindBasePhase = float(abs(int(hash(name + str(global_position))))) * 0.001
	set_process(idleWindEnabled and not cleared)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if idleWindEnabled == false:
		return

	if cleared:
		set_process(false)
		return

	if visualRoot.visible == false:
		return

	var currentTime: float = Time.get_ticks_msec() / 1000.0

	if currentTime < touchShakeUntilTime:
		return

	idleWindUpdateTimer += delta
	if idleWindUpdateInterval > 0.0 and idleWindUpdateTimer < idleWindUpdateInterval:
		return

	idleWindUpdateTimer = 0.0
	applyIdleWindSway(currentTime)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		if tryWaterWithSelectedTool() or tryHoeWithSelectedTool():
			get_viewport().set_input_as_handled()
		return

	if cleared:
		return
	
	if event.is_action_pressed("interact") == false:
		return

	var currentFrame: int = Engine.get_process_frames()

	if lastClearFrame == currentFrame:
		return

	if tryClear():
		lastClearFrame = currentFrame
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node) -> void:
	if cleared:
		return
	
	if body.is_in_group("player") == false:
		return

	shakeGrassPiecesFromBody(body)


func tryClear() -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		return false

	var distance: float = player.global_position.distance_to(global_position)

	if distance > interactDistance:
		return false

	if isClosestClearableToPlayer() == false:
		return false

	if player.has_method("startClearAction"):
		player.startClearAction(self)
	else:
		clearDeadGrass()

	return true


func setCleared(value: bool) -> void:
	cleared = value
	visible = true
	monitoring = not value
	monitorable = not value
	visualRoot.visible = not value
	
	if soilPatchSprite != null:
		soilPatchSprite.visible = true

	for tween in grassTweens.values():
		if tween != null:
			tween.kill()

	grassTweens.clear()

	for grassPivot in grassOriginalRotations.keys():
		if is_instance_valid(grassPivot):
			grassPivot.rotation = grassOriginalRotations[grassPivot]

	var collisionShape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collisionShape != null:
		collisionShape.disabled = value

	idleWindUpdateTimer = 0.0
	set_process(idleWindEnabled and not value)
	applySoilStateVisual()


func isCleared() -> bool:
	return cleared


func getSoilState() -> String:
	return soilState


func getSoilPatchWorldPosition() -> Vector2:
	if soilPatchSprite != null:
		return soilPatchSprite.global_position

	return global_position


func setSoilState(newState: String) -> void:
	match newState:
		"watered":
			soilState = "watered"
		"recovered":
			soilState = "recovered"
		"converted":
			soilState = "converted"
		"restored":
			soilState = "restored"
		_:
			soilState = "dry"

	applySoilStateVisual()


func applySoilStateVisual() -> void:
	if recoverySprite != null:
		recoverySprite.visible = cleared and soilState == "recovered"

	if soilPatchSprite != null:
		soilPatchSprite.visible = soilState != "converted" and soilState != "restored"

		match soilState:
			"watered":
				soilPatchSprite.modulate = Color(0.62, 0.58, 0.48, 1.0)
			"recovered":
				soilPatchSprite.modulate = Color(0.72, 0.78, 0.56, 1.0)
			_:
				soilPatchSprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if soilState == "converted" or soilState == "restored":
		visualRoot.visible = false


func tryWaterWithSelectedTool() -> bool:
	if cleared == false:
		return false

	if toolManager == null:
		toolManager = get_tree().get_first_node_in_group("tool_manager")

	if toolManager == null:
		return false

	if toolManager.has_method("isWateringCanSelected") == false:
		return false

	if bool(toolManager.call("isWateringCanSelected")) == false:
		return false

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		return false

	var targetWorldPosition: Vector2 = get_global_mouse_position()

	if isClosestDrySoilPatchToWaterTarget(targetWorldPosition) == false:
		return false

	return waterSoilPatch()


func tryHoeWithSelectedTool() -> bool:
	if cleared == false:
		if debugLog:
			print("DeadGrass hoe rejected: not cleared. target: ", name)
		return false

	if toolManager == null:
		toolManager = get_tree().get_first_node_in_group("tool_manager")

	if toolManager == null:
		if debugLog:
			print("DeadGrass hoe rejected: ToolManager missing. target: ", name)
		return false

	if toolManager.has_method("isHoeSelected") == false:
		if debugLog:
			print("DeadGrass hoe rejected: ToolManager has no isHoeSelected. target: ", name)
		return false

	if bool(toolManager.call("isHoeSelected")) == false:
		return false

	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		if debugLog:
			print("DeadGrass hoe rejected: player missing. target: ", name)
		return false

	var targetWorldPosition: Vector2 = get_global_mouse_position()
	var soilPatchWorldPosition: Vector2 = getSoilPatchWorldPosition()

	debugPrintHoeTarget("tryHoeWithSelectedTool", targetWorldPosition, soilPatchWorldPosition)

	if isClosestRecoveredSoilPatchToHoeTarget(targetWorldPosition) == false:
		if debugLog:
			print("DeadGrass hoe rejected: not closest recovered target. target: ", name)
		return false

	if fieldArea == null:
		fieldArea = get_tree().get_first_node_in_group("field_area")

	if fieldArea == null:
		if debugLog:
			print("DeadGrass hoe rejected: FieldArea missing. target: ", name)
		return false

	if fieldArea.has_method("canConvertRecoveredSoilAtWorldPosition"):
		var canConvert := bool(fieldArea.call("canConvertRecoveredSoilAtWorldPosition", soilPatchWorldPosition))
		if debugLog:
			print("DeadGrass hoe canConvertRecoveredSoilAtWorldPosition: ", canConvert, " target: ", name)
		if canConvert == false:
			if fieldArea.has_method("isWorldPositionFarmBlocked"):
				var farmBlocked := bool(fieldArea.call("isWorldPositionFarmBlocked", soilPatchWorldPosition))
				if debugLog:
					print("DeadGrass hoe farmBlocked for restored check: ", farmBlocked, " target: ", name)
				if farmBlocked:
					setSoilState("restored")
					return true

			return false

	if player.has_method("startHoeAction"):
		var startedHoeAction := bool(player.call("startHoeAction", Callable(self, "hoeRecoveredSoilPatch")))
		if debugLog:
			print("DeadGrass hoe startHoeAction result: ", startedHoeAction, " target: ", name)
		return startedHoeAction

	return hoeRecoveredSoilPatch()


func waterSoilPatch() -> bool:
	if cleared == false:
		return false

	if soilState != "dry":
		return false

	setSoilState("watered")

	if debugLog:
		print("Watered DeadGrass soil patch: ", name)

	return true


func isClosestDrySoilPatchToWaterTarget(targetWorldPosition: Vector2) -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		return false

	var closestObject: Node2D = null
	var closestDistance := INF
	var waterableObjects := get_tree().get_nodes_in_group("waterable_soil_patch")

	for object in waterableObjects:
		if object == null:
			continue

		if object is Node2D == false:
			continue

		if object.visible == false:
			continue

		if object.has_method("isCleared") == false:
			continue

		if bool(object.call("isCleared")) == false:
			continue

		if object.has_method("getSoilState") and str(object.call("getSoilState")) != "dry":
			continue

		var objectNode := object as Node2D
		var soilPatchWorldPosition: Vector2 = objectNode.global_position

		if object.has_method("getSoilPatchWorldPosition"):
			soilPatchWorldPosition = object.call("getSoilPatchWorldPosition")

		var playerDistance := player.global_position.distance_to(soilPatchWorldPosition)
		var targetDistance := targetWorldPosition.distance_to(soilPatchWorldPosition)

		if playerDistance > waterDistance:
			continue

		if targetDistance > waterTargetRadius:
			continue

		if targetDistance < closestDistance:
			closestDistance = targetDistance
			closestObject = objectNode

	return closestObject == self


func hoeRecoveredSoilPatch() -> bool:
	if cleared == false:
		if debugLog:
			print("hoeRecoveredSoilPatch failed: not cleared. target: ", name)
		return false

	if soilState != "recovered":
		if debugLog:
			print("hoeRecoveredSoilPatch failed: soilState is not recovered. target: ", name, " soilState: ", soilState)
		return false

	if fieldArea == null:
		fieldArea = get_tree().get_first_node_in_group("field_area")

	if fieldArea == null:
		if debugLog:
			print("hoeRecoveredSoilPatch failed: FieldArea missing. target: ", name)
		return false

	if fieldArea.has_method("tryConvertRecoveredSoilAtWorldPosition") == false:
		if debugLog:
			print("hoeRecoveredSoilPatch failed: FieldArea missing tryConvertRecoveredSoilAtWorldPosition. target: ", name)
		return false

	var soilPatchWorldPosition: Vector2 = getSoilPatchWorldPosition()
	debugPrintHoeTarget("hoeRecoveredSoilPatch", get_global_mouse_position(), soilPatchWorldPosition)

	if bool(fieldArea.call("tryConvertRecoveredSoilAtWorldPosition", soilPatchWorldPosition)) == false:
		if debugLog:
			print("hoeRecoveredSoilPatch failed: FieldArea conversion returned false. target: ", name)
		return false

	if debugLog:
		print("Converted recovered soil patch to FieldArea cell: ", name)

	return true


func debugPrintHoeTarget(context: String, mouseWorldPosition: Vector2, soilPatchWorldPosition: Vector2) -> void:
	if debugLog == false:
		return

	print(
		"DeadGrass hoe debug [",
		context,
		"] target: ",
		name,
		" cleared: ",
		cleared,
		" soilState: ",
		soilState,
		" mouseWorldPosition: ",
		mouseWorldPosition,
		" soilPatchWorldPosition: ",
		soilPatchWorldPosition,
		" global_position: ",
		global_position
	)

	if player != null:
		print(
			"  playerPosition: ",
			player.global_position,
			" playerDistanceToSoil: ",
			player.global_position.distance_to(soilPatchWorldPosition),
			" targetDistanceToSoil: ",
			mouseWorldPosition.distance_to(soilPatchWorldPosition),
			" waterDistance: ",
			waterDistance,
			" waterTargetRadius: ",
			waterTargetRadius
		)

	if fieldArea != null and fieldArea.has_method("worldToCell"):
		print(
			"  mouseCell: ",
			fieldArea.call("worldToCell", mouseWorldPosition),
			" soilCell: ",
			fieldArea.call("worldToCell", soilPatchWorldPosition)
		)


func shouldAutoConvertAfterClear() -> bool:
	if fieldArea == null:
		fieldArea = get_tree().get_first_node_in_group("field_area")

	if fieldArea == null:
		return false

	if fieldArea.has_method("isWorldPositionOnTilledOrCropCell") == false:
		return false

	return bool(fieldArea.call("isWorldPositionOnTilledOrCropCell", getSoilPatchWorldPosition()))


func isClosestRecoveredSoilPatchToHoeTarget(targetWorldPosition: Vector2) -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		return false

	var closestObject: Node2D = null
	var closestDistance := INF
	var waterableObjects := get_tree().get_nodes_in_group("waterable_soil_patch")

	if debugLog:
		print(
			"Recovered hoe target search from: ",
			name,
			" click: ",
			targetWorldPosition,
			" candidates: ",
			waterableObjects.size()
		)

	for object in waterableObjects:
		if object == null:
			continue

		if object is Node2D == false:
			if debugLog:
				print("  skip non-Node2D candidate: ", object)
			continue

		if object.visible == false:
			if debugLog and object == self:
				print("  skip self: object invisible.")
			continue

		if object.has_method("isCleared") == false:
			if debugLog and object == self:
				print("  skip self: missing isCleared.")
			continue

		if bool(object.call("isCleared")) == false:
			if debugLog and object == self:
				print("  skip self: not cleared.")
			continue

		if object.has_method("getSoilState") == false:
			if debugLog and object == self:
				print("  skip self: missing getSoilState.")
			continue

		if str(object.call("getSoilState")) != "recovered":
			if debugLog and object == self:
				print("  skip self: soilState is not recovered: ", object.call("getSoilState"))
			continue

		var objectNode := object as Node2D
		var soilPatchWorldPosition: Vector2 = objectNode.global_position

		if object.has_method("getSoilPatchWorldPosition"):
			soilPatchWorldPosition = object.call("getSoilPatchWorldPosition")

		var playerDistance := player.global_position.distance_to(soilPatchWorldPosition)
		var targetDistance := targetWorldPosition.distance_to(soilPatchWorldPosition)

		if debugLog:
			print(
				"  recovered candidate: ",
				objectNode.name,
				" soilPos: ",
				soilPatchWorldPosition,
				" playerDistance: ",
				playerDistance,
				" targetDistance: ",
				targetDistance,
				" soilState: ",
				object.call("getSoilState")
			)

		if playerDistance > waterDistance:
			if debugLog and object == self:
				print("  skip self: playerDistance exceeds waterDistance.")
			continue

		if targetDistance > waterTargetRadius:
			if debugLog and object == self:
				print("  skip self: targetDistance exceeds waterTargetRadius.")
			continue

		if targetDistance < closestDistance:
			closestDistance = targetDistance
			closestObject = objectNode

	if debugLog:
		print(
			"Recovered hoe closest target: ",
			closestObject.name if closestObject != null else "<none>",
			" closestDistance: ",
			closestDistance,
			" self: ",
			name,
			" result: ",
			closestObject == self
		)

	return closestObject == self


func isClosestClearableToPlayer() -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D

	if player == null:
		return false

	var closestObject: Node2D = null
	var closestDistance := INF

	var clearableObjects := get_tree().get_nodes_in_group("clearable_object")

	for object in clearableObjects:
		if object == null:
			continue

		if object is Node2D == false:
			continue

		if object.visible == false:
			continue
		
		if object.has_method("isCleared") and bool(object.call("isCleared")):
			continue
		
		if object is Area2D:
			var clearableArea := object as Area2D
			if clearableArea.monitoring == false:
				continue

		var objectNode := object as Node2D
		var distance := player.global_position.distance_to(objectNode.global_position)

		if distance > interactDistance:
			continue

		if distance < closestDistance:
			closestDistance = distance
			closestObject = objectNode

	return closestObject == self


func storeGrassOriginalPositions() -> void:
	grassOriginalPositions.clear()

	for child in visualRoot.get_children():
		if child is Node2D:
			grassOriginalPositions[child] = child.position


func shakeGrassPiecesFromBody(body: Node) -> void:
	if body is Node2D == false:
		return

	var bodyNode := body as Node2D
	touchShakeUntilTime = Time.get_ticks_msec() / 1000.0 + shakeDuration + returnDuration + 0.12

	var directionSign: float = 1.0

	if global_position.x < bodyNode.global_position.x:
		directionSign = -1.0
	else:
		directionSign = 1.0

	var index := 0

	for child in visualRoot.get_children():
		if child is Node2D == false:
			continue

		var grassPivot := child as Node2D

		if grassOriginalRotations.has(grassPivot) == false:
			grassOriginalRotations[grassPivot] = grassPivot.rotation

		var originalRotation: float = grassOriginalRotations[grassPivot]

		if grassTweens.has(grassPivot):
			var oldTween: Tween = grassTweens[grassPivot]
			if oldTween != null:
				oldTween.kill()

		var strengthMultiplier := getShakeStrengthMultiplier(index)
		var delay := getShakeDelay(index)

		var targetRotation := originalRotation + deg_to_rad(8.0 * directionSign * strengthMultiplier)

		var tween := create_tween()
		grassTweens[grassPivot] = tween

		tween.tween_interval(delay)
		tween.tween_property(
			grassPivot,
			"rotation",
			targetRotation,
			shakeDuration
		)
		tween.tween_property(
			grassPivot,
			"rotation",
			originalRotation,
			returnDuration
		)

		index += 1


func applyIdleWindSway(currentTime: float) -> void:
	var amplitude: float = deg_to_rad(idleWindAmplitudeDegrees)
	var index := 0

	for child in visualRoot.get_children():
		if child is Node2D == false:
			continue

		if idleWindMaxPivotCount > 0 and index >= idleWindMaxPivotCount:
			break

		var grassPivot := child as Node2D

		if grassOriginalRotations.has(grassPivot) == false:
			grassOriginalRotations[grassPivot] = grassPivot.rotation

		var originalRotation: float = grassOriginalRotations[grassPivot]
		var phase: float = idleWindBasePhase + float(index) * 0.63
		var localAmplitude: float = amplitude * (0.75 + float(index % 3) * 0.12)
		grassPivot.rotation = originalRotation + sin(currentTime * idleWindSpeed + phase) * localAmplitude

		index += 1


func getShakeStrengthMultiplier(index: int) -> float:
	match index % 4:
		0:
			return 1.0
		1:
			return 0.75
		2:
			return 1.25
		_:
			return 0.9


func getShakeDelay(index: int) -> float:
	return float(index % 4) * 0.025


func getSideOffset(index: int) -> float:
	match index % 3:
		0:
			return -1.5
		1:
			return 0.0
		_:
			return 1.5


func storeGrassOriginalTransforms() -> void:
	grassOriginalRotations.clear()

	for child in visualRoot.get_children():
		if child is Node2D:
			grassOriginalRotations[child] = child.rotation


func getInventoryManager() -> Node:
	return get_tree().get_first_node_in_group("inventory_manager")


func getUIManager() -> Node:
	return get_tree().get_first_node_in_group("ui_manager")


func applyClearReward() -> void:
	if not dropEnabled:
		return
	
	if dropTable.is_empty():
		return
	
	var inventoryManager := get_tree().get_first_node_in_group("inventory_manager")
	if inventoryManager == null:
		return
	
	for dropData in dropTable:
		if not dropData.has("itemId"):
			continue
		
		var itemId: String = str(dropData.get("itemId", ""))
		if itemId == "":
			continue
		
		var chance: float = float(dropData.get("chance", 0.0))
		if chance <= 0.0:
			continue
		
		if randf() > chance:
			continue
		
		var amountMin: int = int(dropData.get("amountMin", 1))
		var amountMax: int = int(dropData.get("amountMax", amountMin))
		
		if amountMin < 1:
			amountMin = 1
		
		if amountMax < amountMin:
			amountMax = amountMin
		
		var amount: int = amountMin
		if amountMax > amountMin:
			amount = randi_range(amountMin, amountMax)
		
		inventoryManager.addItem(itemId, amount)
		showFoundItemFeedback(itemId, amount)


func showFoundItemFeedback(itemId: String, amount: int) -> void:
	var ui := get_tree().get_first_node_in_group("ui_manager")
	if ui == null:
		return
	
	if not ui.has_method("showLocalizedFeedbackText"):
		return
	
	var itemName := getItemDisplayName(itemId)
	
	if amount <= 1:
		ui.showLocalizedFeedbackText("feedback.found_item", [itemName])
	else:
		ui.showLocalizedFeedbackText("feedback.found_item_amount", [itemName, amount])


func getItemDisplayName(itemId: String) -> String:
	var itemDatabase := get_tree().get_first_node_in_group("item_database")
	var localizationManager := get_tree().get_first_node_in_group("localization_manager")
	
	if itemDatabase != null:
		if itemDatabase.has_method("getDisplayNameKey"):
			var displayNameKey: String = itemDatabase.getDisplayNameKey(itemId)
			if displayNameKey != "":
				if localizationManager != null and localizationManager.has_method("trText"):
					return localizationManager.trText(displayNameKey)
		
		if itemDatabase.has_method("getDisplayName"):
			var displayName: String = itemDatabase.getDisplayName(itemId)
			if displayName != "":
				return displayName
	
	return itemId


func clearDeadGrass() -> void:
	if cleared:
		return

	if fieldArea == null:
		fieldArea = get_tree().get_first_node_in_group("field_area")

	if revealFieldDryDirtOnClear and fieldArea != null and fieldArea.has_method("clearGroundAtWorldPosition"):
		fieldArea.clearGroundAtWorldPosition(global_position)

	if vegetationSpawner == null:
		vegetationSpawner = get_tree().get_first_node_in_group("vegetation_spawner")

	if vegetationSpawner != null and vegetationSpawner.has_method("markVegetationCleared"):
		vegetationSpawner.markVegetationCleared(name)

	if debugLog:
		print("Cleared DeadGrassPatch: ", name)
		print("Clearing vegetation id: ", name)

	setCleared(true)

	if shouldAutoConvertAfterClear():
		setSoilState("converted")

	applyClearReward()
