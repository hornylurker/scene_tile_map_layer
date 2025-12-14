@tool
extends Node2D
class_name SceneTileMapLayer

enum Mode { DRAW, SELECT }

@export var grid_size: Vector2 = Vector2(64, 64):
	get():
		return grid_size
	set(value):
		grid_size = value
		if grid_overlay:
			grid_overlay.grid_size = value

@export var tileset: Dictionary[String, PackedScene] = {}

@export var active_scene_key: String:
	get():
		return active_scene_key
	set(value):
		active_scene_key = value
		if Engine.is_editor_hint():
			if mode == Mode.DRAW:
				show_preview()
			queue_redraw()

var mode: Mode = Mode.SELECT:
	get():
		return mode
	set(value):
		mode = value
		if Engine.is_editor_hint():
			if mode == Mode.DRAW:
				show_preview()
				show_preview_node_properties()
			elif mode == Mode.SELECT:
				hide_preview()
				EditorInterface.get_inspector().edit(self)

var grid_overlay: GridOverlay = null
var scene_tile_map_pannel: SceneTileMapPannel
var preview_node: Node2D = null
var undo_redo: EditorUndoRedoManager = null

func _ready():
	mode = Mode.SELECT

func enable(overlay: GridOverlay, scene_tile_map_pannel_: SceneTileMapPannel) -> void:
	grid_overlay = overlay
	grid_overlay.grid_size = grid_size
	grid_overlay.enabled = true
	undo_redo = grid_overlay.editor_plugin.get_undo_redo()
	scene_tile_map_pannel = scene_tile_map_pannel_
	scene_tile_map_pannel.scene_tile_map = self

func disable() -> void:
	grid_overlay.enabled = false
	grid_overlay = null

func show_preview_node_properties():
	EditorInterface.get_inspector().edit(preview_node)

func init_preview():
	preview_node = tileset[active_scene_key].instantiate()
	if preview_node.get_parent():
		preview_node.get_parent().remove_child(preview_node)
	preview_node.name = '_preview_node_tscn_key'
	preview_node.z_index = 10

func clone_preview(scene: Node2D):
	preview_node = scene.duplicate()
	if preview_node.get_parent():
		preview_node.get_parent().remove_child(preview_node)
	preview_node.name = '_preview_node_tscn_key'
	preview_node.z_index = 10

func show_preview():
	if preview_node == null:
		init_preview()
	assert(preview_node != null)
	assert(not preview_node.get_parent())
	add_child(preview_node)

func hide_preview():
	if preview_node != null:
		var parent = preview_node.get_parent()
		if parent != null:
			parent.remove_child(preview_node)

func tile_to_pos(tile: Vector2i) -> Vector2:
	return Vector2(tile) * grid_size + grid_size / 2

func pos_to_tile(pos: Vector2) -> Vector2i:
	return Vector2(
		floori(pos.x / grid_size.x),
		floori(pos.y / grid_size.y),
	)

func undo_redo_place_scene_at(tile: Vector2i) -> void:
	var scene = preview_node.duplicate()
	scene.position = tile_to_pos(tile)
	assert(not scene.get_parent())

	undo_redo.add_do_method(self, "undo_redo_add_child_with_owner", scene)
	undo_redo.add_undo_method(scene, "queue_free")


func preview_scene_at(tile: Vector2i) -> void:
	if preview_node != null:
		preview_node.position = tile_to_pos(tile)

func get_scenes_at(tile: Vector2i) -> Array[Node2D]:
	var scenes: Array[Node2D] = []
	for scene in get_children():
		if pos_to_tile(scene.position) == tile and scene != preview_node:
			scenes.append(scene)
	return scenes

func select_scene_at(tile: Vector2i) -> void:
	var scenes := get_scenes_at(tile)
	if scenes.size() == 0:
		return
	if scenes.size() > 1:
		push_error("Can't select scene at tile %s because it contains more than one scene" % str(tile))
		return
	var scene: Node = scenes[0]
	var scene_path = scene.scene_file_path
	for key in tileset:
		var packed: PackedScene = tileset[key]
		if scene_path == packed.resource_path:
			active_scene_key = key
			clone_preview(scene)
			show_preview_node_properties()
			break

func undo_redo_remove_scenes_at(tile: Vector2i) -> void:
	for child in get_scenes_at(tile):
		var data = undo_redo_pack_node(child)
		undo_redo.add_do_method(child, "queue_free")
		undo_redo.add_undo_method(self, "undo_redo_restore_child", data)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _get_tile_by_event(event: InputEvent) -> Vector2i:
	var transform: = EditorInterface.get_editor_viewport_2d().global_canvas_transform
	var scale: Vector2 = transform.get_scale()
	var pos: Vector2 = (event.position - transform.origin) / scale
	return pos_to_tile(pos)

func handle_gui_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		if mode == Mode.DRAW:
			var tile := _get_tile_by_event(event)
			preview_scene_at(tile)
		return true
	elif event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			var tile := _get_tile_by_event(event)
			if mode == Mode.DRAW:
				undo_redo.create_action("Place tile")
				undo_redo_remove_scenes_at(tile)
				undo_redo_place_scene_at(tile)
				undo_redo.commit_action()
			elif mode == Mode.SELECT:
				select_scene_at(tile)
		return true
	return false

func undo_redo_pack_node(child: Node):
	var packed := PackedScene.new()
	packed.pack(child)
	return {
		"scene": packed,
		"parent": child.get_parent(),
		"index": child.get_index()
	}

func undo_redo_restore_child(data):
	var node = data.scene.instantiate()
	data.parent.add_child(node)
	data.parent.move_child(node, data.index)

func undo_redo_add_child_with_owner(scene):
	add_child(scene)
	scene.owner = get_tree().edited_scene_root
