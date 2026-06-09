extends Node2D

@export var treeId: String = "big_tree_01"
@export var chunkId: Vector2i = Vector2i.ZERO
@export var debugLog: bool = false

func _ready() -> void:
	add_to_group("world_object")
	add_to_group("tree_object")

	if debugLog:
		print("Tree ready: ", treeId, " chunk: ", chunkId)
