@tool
extends Node2D
class_name SceneTileMapLayer

signal grid_size_changed(Vector2)
signal tileset_changed(SceneTileSet)

@export var grid_size: Vector2 = Vector2(64, 64):
	get():
		return grid_size
	set(value):
		if grid_size != value:
			grid_size = value
			if Engine.is_editor_hint():
				grid_size_changed.emit(value)
		
@export var tileset: SceneTileSet = null:
	get():
		return tileset
	set(value):
		if tileset != value:
			tileset = value
			if Engine.is_editor_hint():
				tileset_changed.emit(value)
