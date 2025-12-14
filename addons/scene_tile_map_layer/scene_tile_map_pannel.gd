@tool
class_name SceneTileMapPannel
extends Control

@export var scene_tile_map: SceneTileMapLayer
@onready var label: Label = $VBoxContainer/Label

func _on_draw_pressed() -> void:
	scene_tile_map.mode = scene_tile_map.Mode.DRAW


func _on_select_pressed() -> void:
	scene_tile_map.mode = scene_tile_map.Mode.SELECT
