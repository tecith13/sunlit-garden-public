extends Node2D
class_name WorldPrototypeRendererManager

@export var prototypeRenderersEnabled: bool = true
@export var debugDrawersEnabled: bool = false
@export var miniMapEnabled: bool = true
@export var printDebug: bool = true


func _ready() -> void:
	add_to_group("world_prototype_renderer_manager")
	call_deferred("applyRendererState")
	
	if printDebug:
		print("WorldPrototypeRendererManager ready.")


func applyRendererState() -> void:
	setPrototypeChildrenEnabled(prototypeRenderersEnabled)
	setDebugDrawersEnabled(debugDrawersEnabled)
	setMiniMapEnabled(miniMapEnabled)


func setPrototypeChildrenEnabled(enabled: bool) -> void:
	visible = enabled
	
	for child in get_children():
		applyRenderEnabledRecursive(child, enabled)


func setDebugDrawersEnabled(enabled: bool) -> void:
	var worldAreaDebugDrawer: Node = findNodeByName("WorldAreaDebugDrawer")
	var terrainDebugDrawer: Node = findNodeByName("TerrainDebugDrawer")
	var terrainVisualDebugRenderer: Node = findNodeByName("TerrainVisualDebugRenderer")
	
	if worldAreaDebugDrawer != null:
		applyRenderEnabledRecursive(worldAreaDebugDrawer, enabled)
	
	if terrainDebugDrawer != null:
		applyRenderEnabledRecursive(terrainDebugDrawer, enabled)
	
	if terrainVisualDebugRenderer != null:
		applyRenderEnabledRecursive(terrainVisualDebugRenderer, enabled)


func setMiniMapEnabled(enabled: bool) -> void:
	var miniMap: Node = findNodeByName("StarterRegionMiniMapDebug")
	
	if miniMap != null:
		applyRenderEnabledRecursive(miniMap, enabled)


func applyRenderEnabledRecursive(node: Node, enabled: bool) -> void:
	if node is CanvasItem:
		var canvasItem: CanvasItem = node as CanvasItem
		canvasItem.visible = enabled
	
	if "renderEnabled" in node:
		node.set("renderEnabled", enabled)
	
	if "debugVisible" in node:
		node.set("debugVisible", enabled)
	
	for child in node.get_children():
		applyRenderEnabledRecursive(child, enabled)


func findNodeByName(targetName: String) -> Node:
	var root: Node = get_tree().current_scene
	
	if root == null:
		return null
	
	return findNodeByNameRecursive(root, targetName)


func findNodeByNameRecursive(node: Node, targetName: String) -> Node:
	if node.name == targetName:
		return node
	
	for child in node.get_children():
		var result: Node = findNodeByNameRecursive(child, targetName)
		
		if result != null:
			return result
	
	return null


func enablePrototypeRenderers() -> void:
	prototypeRenderersEnabled = true
	setPrototypeChildrenEnabled(true)


func disablePrototypeRenderers() -> void:
	prototypeRenderersEnabled = false
	setPrototypeChildrenEnabled(false)


func enableDebugDrawers() -> void:
	debugDrawersEnabled = true
	setDebugDrawersEnabled(true)


func disableDebugDrawers() -> void:
	debugDrawersEnabled = false
	setDebugDrawersEnabled(false)


func enableMiniMap() -> void:
	miniMapEnabled = true
	setMiniMapEnabled(true)


func disableMiniMap() -> void:
	miniMapEnabled = false
	setMiniMapEnabled(false)


func refreshAllPrototypeRenderers() -> void:
	for child in get_children():
		refreshRendererRecursive(child)


func refreshRendererRecursive(node: Node) -> void:
	if node.has_method("refreshRenderer"):
		node.call("refreshRenderer")
	elif node.has_method("refreshRoad"):
		node.call("refreshRoad")
	elif node.has_method("refreshBrook"):
		node.call("refreshBrook")
	elif node.has_method("refreshSquare"):
		node.call("refreshSquare")
	elif node.has_method("refreshStall"):
		node.call("refreshStall")
	elif node.has_method("refreshMailbox"):
		node.call("refreshMailbox")
	elif node.has_method("refreshTradeArea"):
		node.call("refreshTradeArea")
	elif node.has_method("refreshForestPath"):
		node.call("refreshForestPath")
	elif node.has_method("refreshLots"):
		node.call("refreshLots")
	elif node.has_method("refreshTiles"):
		node.call("refreshTiles")
	
	for child in node.get_children():
		refreshRendererRecursive(child)
