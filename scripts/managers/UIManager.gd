extends CanvasLayer

@onready var dayLabel: Label = $StatusPanel/StatusRoot/StatusList/DayLabel
@onready var moneyLabel: Label = $StatusPanel/StatusRoot/StatusList/MoneyRow/MoneyLabel
@onready var toolLabel: Label = $StatusPanel/StatusRoot/StatusList/ToolRow/ToolLabel
@onready var seedLabel: Label = $StatusPanel/StatusRoot/StatusList/SeedRow/SeedLabel
@onready var carrotLabel: Label = $StatusPanel/StatusRoot/StatusList/CarrotRow/CarrotLabel

@onready var seedIcon: TextureRect = $StatusPanel/StatusRoot/StatusList/SeedRow/SeedIcon
@onready var carrotIcon: TextureRect = $StatusPanel/StatusRoot/StatusList/CarrotRow/CarrotIcon
@onready var moneyIcon: TextureRect = $StatusPanel/StatusRoot/StatusList/MoneyRow/MoneyIcon
@onready var toolIcon: TextureRect = $StatusPanel/StatusRoot/StatusList/ToolRow/ToolIcon

@onready var feedbackLabel: Label = $FeedbackLabel

var gameManager: Node = null
var inventoryManager: Node = null
var toolManager: Node = null
var localizationManager: Node = null

var feedbackTween: Tween = null

var moneyIconTexture: Texture2D = preload("res://assets/sprites/icons/money_icon.png")
var toolIconTextures: Dictionary = {
	"Hand": preload("res://assets/sprites/icons/tool_hand_icon.png"),
	"Hoe": preload("res://assets/sprites/icons/tool_hoe_icon.png"),
	"Watering Can": preload("res://assets/sprites/icons/tool_watering_can_icon.png"),
	"Seed": preload("res://assets/sprites/icons/tool_seed_icon.png")
}

func _ready() -> void:
	add_to_group("ui_manager")

	if feedbackLabel != null:
		feedbackLabel.visible = false
		feedbackLabel.modulate.a = 1.0
	
	if moneyIcon != null:
		moneyIcon.texture = moneyIconTexture
		
	refreshReferences()
	updateStatus()


func _process(_delta: float) -> void:
	updateStatus()


func refreshReferences() -> void:
	if gameManager == null:
		gameManager = get_tree().get_first_node_in_group("game_manager")

	if inventoryManager == null:
		inventoryManager = get_tree().get_first_node_in_group("inventory_manager")

	if toolManager == null:
		toolManager = get_tree().get_first_node_in_group("tool_manager")

	if localizationManager == null:
		localizationManager = get_tree().get_first_node_in_group("localization_manager")


func getText(key: String) -> String:
	if localizationManager == null:
		localizationManager = get_tree().get_first_node_in_group("localization_manager")

	if localizationManager != null and localizationManager.has_method("trText"):
		return localizationManager.trText(key)

	return key


func getToolDisplayName(toolName: String) -> String:
	match toolName:
		"Hand":
			return getText("tool.hand")
		"Hoe":
			return getText("tool.hoe")
		"Watering Can":
			return getText("tool.watering_can")
		"Seed":
			return getText("tool.seed")
		_:
			return toolName


func updateStatus() -> void:
	refreshReferences()

	if gameManager != null:
		dayLabel.text = getText("ui.day_count") % [gameManager.currentDay]

	if inventoryManager != null:
		moneyLabel.text = "%d" % inventoryManager.getMoney()

		seedLabel.text = "%d" % inventoryManager.getItemCount("carrot_seed")
		carrotLabel.text = "%d" % inventoryManager.getItemCount("carrot")

	if toolManager != null:
		var currentToolName: String = toolManager.getCurrentToolName()

		toolLabel.text = getToolDisplayName(currentToolName)

		if toolIcon != null:
			if toolIconTextures.has(currentToolName):
				toolIcon.texture = toolIconTextures[currentToolName]
			else:
				toolIcon.texture = null


func showFeedbackText(message: String) -> void:
	if feedbackLabel == null:
		return

	if feedbackTween != null:
		feedbackTween.kill()

	feedbackLabel.text = message
	feedbackLabel.visible = true
	feedbackLabel.modulate.a = 1.0

	var startY := 420.0
	var endY := 390.0

	feedbackLabel.position.y = startY

	feedbackTween = create_tween()
	feedbackTween.tween_property(feedbackLabel, "position:y", endY, 0.25)
	feedbackTween.tween_interval(0.6)
	feedbackTween.tween_property(feedbackLabel, "modulate:a", 0.0, 0.25)
	feedbackTween.tween_callback(func():
		feedbackLabel.visible = false
		feedbackLabel.position.y = startY
		feedbackLabel.modulate.a = 1.0
	)


func showLocalizedFeedbackText(key: String, values: Array = []) -> void:
	var message := getText(key)

	if values.size() > 0:
		message = message % values

	showFeedbackText(message)
