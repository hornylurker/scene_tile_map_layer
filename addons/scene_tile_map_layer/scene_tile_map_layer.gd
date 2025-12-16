@tool
extends Node2D
class_name SceneTileMapLayer

signal grid_size_changed(Vector2)

@export var grid_size: Vector2 = Vector2(64, 64):
	get():
		return grid_size
	set(value):
		grid_size = value
		grid_size_changed.emit(grid_size)
		
@export var tileset: Dictionary[String, PackedScene] = {}
