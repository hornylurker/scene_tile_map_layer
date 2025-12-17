@tool
class_name GridOverlay
extends Control

const MAX_LINES = 200

enum Mode { DRAW, SELECT }

signal tilemap_layer_changed(SceneTileMapLayer)
signal editor_property_changed
signal enabled_changed(bool)

var editor_plugin: EditorPlugin
var grid_size: Vector2
var grid_color: Color
var line_width: int

var enabled := false:
	get():
		return enabled
	set(value):
		enabled = value
		enabled_changed.emit(value)
var mode: Mode = Mode.SELECT
var tilemap_layer: SceneTileMapLayer = null
var preview_node: Node2D
var undo_redo: EditorUndoRedoManager

func _init(editor_plugin_: EditorPlugin, grid_size_: Vector2, grid_color_: Color, line_width_: int) -> void:
	editor_plugin = editor_plugin_
	grid_size = grid_size_
	grid_color = grid_color_
	line_width = line_width_

func _ready() -> void:
	set_process(true)
	set_mouse_filter(MOUSE_FILTER_IGNORE)
	undo_redo = editor_plugin.get_undo_redo()
	
	var inspector := EditorInterface.get_inspector()
	inspector.property_edited.connect(_on_props_changed)

func _on_props_changed(_property: String) -> void:
	if not enabled:
		return
	editor_property_changed.emit()

func _process(delta) -> void:
	queue_redraw()

func _draw() -> void:
	if not enabled:
		return

	draw_grid(
		get_viewport_rect().size,
		EditorInterface.get_editor_viewport_2d().global_canvas_transform,
	)

func draw_grid(size: Vector2, transform: Transform2D) -> void:
	var offset = transform.origin
	var scale := transform.get_scale()
	var num_to_negative: Vector2i = offset / scale / grid_size
	var total_num: Vector2i = size / scale / grid_size

	var hlines := total_num.x + 1
	var vlines := total_num.y + 1
	if hlines > MAX_LINES or vlines > MAX_LINES:
		return

	for i in range(hlines):
		draw_line(
			Vector2(
				grid_size.x * (i - num_to_negative.x),
				grid_size.y * (-1 - num_to_negative.y)
			),
			Vector2(
				grid_size.x * (i - num_to_negative.x),
				grid_size.y * (total_num.y + 1 - num_to_negative.y)
			),
			grid_color, line_width)

	for i in range(vlines):
		draw_line(
			Vector2(
				grid_size.x * (-1 - num_to_negative.x),
				grid_size.y * (i - num_to_negative.y),
			),
			Vector2(
				grid_size.x * (total_num.x + 1 - num_to_negative.x),
				grid_size.y * (i - num_to_negative.y),
			),
			grid_color, line_width)

func set_tilemap_layer(layer: SceneTileMapLayer) -> void:
	if tilemap_layer == layer:
		return
	if tilemap_layer != null:
		remove_preview()
		tilemap_layer.grid_size_changed.disconnect(on_grid_size_changed)
		tilemap_layer.tileset_changed.disconnect(on_tileset_changed)
		tilemap_layer = null
		on_tileset_changed(null)
	if layer != null:
		tilemap_layer = layer
		tilemap_layer.grid_size_changed.connect(on_grid_size_changed)
		tilemap_layer.tileset_changed.connect(on_tileset_changed)
		on_tileset_changed(tilemap_layer.tileset)
	tilemap_layer_changed.emit(tilemap_layer)

func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if mode == Mode.DRAW:
		if preview_node != null:
			preview_node.visible = true
			show_preview_node_properties()
		else:
			push_warning('Scene for drawing not specified. Use scene from tileset or select node from tilemap layer.')
	elif mode == Mode.SELECT:
		if preview_node != null:
			preview_node.visible = false
		if tilemap_layer:
			EditorInterface.get_inspector().edit(tilemap_layer)

func on_grid_size_changed(grid_size_: Vector2) -> void:
	grid_size = grid_size_

func on_tileset_changed(tileset: SceneTileSet) -> void:
	enabled = tileset != null
	if not enabled:
		remove_preview()

func handle_gui_input(event: InputEvent) -> bool:
	if not enabled or tilemap_layer == null:
		return false

	if event is InputEventMouseMotion:
		if mode == Mode.DRAW:
			var tile := get_tile_by_event(event)
			preview_scene_at(tile)
		return true
	elif event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed == false:
			var tile := get_tile_by_event(event)
			if mode == Mode.DRAW:
				undo_redo.create_action("Place tile")
				undo_redo_remove_scenes_at(tile)
				undo_redo_place_scene_at(tile)
				undo_redo.commit_action()
			elif mode == Mode.SELECT:
				select_scene_at(tile)
		elif event.button_index == 2 and event.pressed == false:
			var tile := get_tile_by_event(event)
			if mode == Mode.DRAW:
				undo_redo.create_action("Remove tile")
				undo_redo_remove_scenes_at(tile)
				undo_redo.commit_action()
		return true
	return false

func init_preview(key: String) -> void:
	_make_preview(tilemap_layer.tileset.scene_get_instance(key))

func clone_preview(scene: Node2D) -> void:
	_make_preview(scene.duplicate())

func _make_preview(scene: Node2D) -> void:
	var old_pos := Vector2.ZERO
	if preview_node != null:
		old_pos = preview_node.position
		preview_node.queue_free()
	preview_node = scene
	if preview_node.get_parent():
		preview_node.get_parent().remove_child(preview_node)
	preview_node.name = '_preview_node_tscn_key'
	preview_node.position = old_pos
	preview_node.visible = mode == Mode.DRAW
	assert(preview_node != null)
	assert(not preview_node.get_parent())
	add_child(preview_node)

func show_preview_node_properties() -> void:
	EditorInterface.get_inspector().edit(preview_node)
	editor_property_changed.emit()

func remove_preview() -> void:
	if preview_node != null:
		if preview_node.get_parent():
			preview_node.get_parent().remove_child(preview_node)
		preview_node = null

func preview_scene_at(tile: Vector2i) -> void:
	if preview_node != null:
		preview_node.position = tile_to_pos(tile)


func tile_to_pos(tile: Vector2i) -> Vector2:
	return Vector2(tile) * grid_size + grid_size / 2

func pos_to_tile(pos: Vector2) -> Vector2i:
	return Vector2(
		floori(pos.x / grid_size.x),
		floori(pos.y / grid_size.y),
	)

func get_tile_by_event(event: InputEvent) -> Vector2i:
	var transform: = EditorInterface.get_editor_viewport_2d().global_canvas_transform
	var scale: Vector2 = transform.get_scale()
	var pos: Vector2 = (event.position - transform.origin) / scale
	return pos_to_tile(pos)

func get_scenes_at(tile: Vector2i) -> Array[Node2D]:
	var scenes: Array[Node2D] = []
	for child in tilemap_layer.get_children():
		if child != preview_node and pos_to_tile(child.position) == tile:
			scenes.append(child)
	return scenes

func select_scene_at(tile: Vector2i) -> void:
	var scenes := get_scenes_at(tile)
	if scenes.size() == 0:
		return
	if scenes.size() > 1:
		push_error("Can't select scene at tile %s because it contains more than one scene" % str(tile))
		return
	clone_preview(scenes[0])
	show_preview_node_properties()

func select_scene_by_key(key: String) -> void:
	init_preview(key)
	show_preview_node_properties()

func add_scene_to_tileset(key: String, node: Node2D) -> bool:
	return tilemap_layer.tileset.scene_add(key, node)

func undo_redo_place_scene_at(tile: Vector2i) -> void:
	var scene = preview_node.duplicate()
	print(scene)
	scene.position = tile_to_pos(tile)
	assert(not scene.get_parent())

	undo_redo.add_do_method(self, "undo_redo_add_child_with_owner", scene)
	undo_redo.add_undo_method(scene, "queue_free")

func undo_redo_remove_scenes_at(tile: Vector2i) -> void:
	for child in get_scenes_at(tile):
		var data = pack_node(child)
		undo_redo.add_do_method(child, "queue_free")
		undo_redo.add_undo_method(self, "undo_redo_restore_child", data)


func pack_node(child: Node):
	var packed := PackedScene.new()
	packed.pack(child)
	assert(child.get_parent() != null)
	return {
		"scene": packed,
		"parent": child.get_parent(),
		"index": child.get_index()
	}

func undo_redo_restore_child(data) -> void:
	var node = data.scene.instantiate()
	data.parent.add_child(node)
	data.parent.move_child(node, data.index)

func undo_redo_add_child_with_owner(scene) -> void:
	tilemap_layer.add_child(scene)
	scene.owner = tilemap_layer.get_tree().edited_scene_root
