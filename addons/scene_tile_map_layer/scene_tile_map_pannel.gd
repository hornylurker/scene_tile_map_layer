@tool
class_name SceneTileMapPannel
extends Control

var grid_overlay: GridOverlay

func _on_draw_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.DRAW)

func _on_select_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.SELECT)
