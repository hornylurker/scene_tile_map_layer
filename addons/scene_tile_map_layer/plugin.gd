@tool
extends EditorPlugin

var grid_overlay: GridOverlay = null
var current_tilemap: SceneTileMapLayer = null
var selection: EditorSelection
var scene_tile_map_pannel: Control

func _enter_tree():
	grid_overlay = GridOverlay.new(
		self,
		Vector2(64, 64),
		Color(1.0, 0.5, 0.5, 0.5),
		-1)
	EditorInterface.get_editor_viewport_2d().add_child(grid_overlay)

	selection = EditorInterface.get_selection()
	selection.selection_changed.connect(_on_selection_changed)

func _exit_tree():
	selection.selection_changed.disconnect(_on_selection_changed)
	if scene_tile_map_pannel != null:
		remove_control_from_bottom_panel(scene_tile_map_pannel)

	if grid_overlay:
		grid_overlay.queue_free()

func _on_selection_changed():
	var nodes = selection.get_selected_nodes()
	if nodes.size() == 1 and nodes[0] is SceneTileMapLayer:
		if current_tilemap != nodes[0]:
			if current_tilemap != null:
				current_tilemap.disable()
			current_tilemap = nodes[0]
			if scene_tile_map_pannel == null:
				scene_tile_map_pannel = preload("res://addons/scene_tilemap_editor_plugin/scene_tile_map_pannel.tscn").instantiate()
				add_control_to_bottom_panel(scene_tile_map_pannel, "Scene TileMap")
			current_tilemap.enable(grid_overlay, scene_tile_map_pannel)
	elif current_tilemap != null:
		current_tilemap.disable()
		current_tilemap = null

func _handles(object: Object) -> bool:
	return true

func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if current_tilemap:
		return current_tilemap.handle_gui_input(event)
	return false
