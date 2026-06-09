extends Node

# 현재 선택 가능한 도구 목록.
enum ToolType {
	HAND,
	HOE,
	WATERING_CAN,
	SEED
}

# 현재 선택된 도구.
var currentTool: ToolType = ToolType.HAND


func _ready() -> void:
	printCurrentTool()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select_hand"):
		setCurrentTool(ToolType.HAND)

	if event.is_action_pressed("select_hoe"):
		setCurrentTool(ToolType.HOE)

	if event.is_action_pressed("select_watering_can"):
		setCurrentTool(ToolType.WATERING_CAN)

	if event.is_action_pressed("select_seed"):
		setCurrentTool(ToolType.SEED)


func setCurrentTool(toolType: ToolType) -> void:
	currentTool = toolType
	printCurrentTool()


func getCurrentTool() -> ToolType:
	return currentTool


func isHoeSelected() -> bool:
	return currentTool == ToolType.HOE


func isWateringCanSelected() -> bool:
	return currentTool == ToolType.WATERING_CAN


func isSeedSelected() -> bool:
	return currentTool == ToolType.SEED


func isHandSelected() -> bool:
	return currentTool == ToolType.HAND


func printCurrentTool() -> void:
	print("Current Tool: ", getToolName(currentTool))


func getCurrentToolName() -> String:
	return getToolName(currentTool)
	
	
func getToolName(toolType: ToolType) -> String:
	match toolType:
		ToolType.HAND:
			return "Hand"
		ToolType.HOE:
			return "Hoe"
		ToolType.WATERING_CAN:
			return "Watering Can"
		ToolType.SEED:
			return "Seed"
		_:
			return "Unknown"



	
