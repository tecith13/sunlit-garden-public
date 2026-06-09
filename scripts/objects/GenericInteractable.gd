extends Area2D
class_name GenericInteractable

@export var interactDistance: float = 72.0
@export var debugLog: bool = false
@export var interactEnabled: bool = true

var player: Node2D = null
var uiManager: Node = null
var localizationManager: Node = null


func _ready() -> void:
	add_to_group("interactable_object")
	refreshReferences()


func _input(event: InputEvent) -> void:
	if not interactEnabled:
		return
	
	if event.is_action_pressed("interact"):
		tryInteract()


func refreshReferences() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	
	if uiManager == null:
		uiManager = get_tree().get_first_node_in_group("ui_manager")
	
	if localizationManager == null:
		localizationManager = get_tree().get_first_node_in_group("localization_manager")


func tryInteract() -> void:
	refreshReferences()
	
	if not canInteract():
		return
	
	onInteract()


func canInteract() -> bool:
	if player == null:
		return false
	
	var distance: float = player.global_position.distance_to(getInteractPointGlobalPosition())
	
	if distance > interactDistance:
		if debugLog:
			print(name, " too far. Distance: ", distance)
		return false
	
	return true


func getInteractPointGlobalPosition() -> Vector2:
	var marker := get_node_or_null("InteractionPoint")
	
	if marker != null and marker is Node2D:
		return (marker as Node2D).global_position
	
	return global_position


func onInteract() -> void:
	if debugLog:
		print(name, " interacted.")


func showFeedback(message: String) -> void:
	if uiManager != null and uiManager.has_method("showFeedbackText"):
		uiManager.showFeedbackText(message)


func showLocalizedFeedback(key: String, values: Array = []) -> void:
	var message: String = key
	
	if localizationManager != null and localizationManager.has_method("trText"):
		message = localizationManager.trText(key)
	
	if values.size() > 0:
		message = message % values
	
	showFeedback(message)
