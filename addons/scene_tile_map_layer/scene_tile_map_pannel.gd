@tool
class_name SceneTileMapPannel
extends Control

@onready var grid_overlay: GridOverlay
@onready var header: HBoxContainer = $Root/Header
@onready var scenes_list: VBoxContainer = $Root/Body/ScenesPanel/ScrollContainer/ScenesList
var scene_picker: EditorResourcePicker
@onready var scene_loader_container: Control = $Root/Header/SceneLoaderContainer
@onready var scene_preview: Control = $Root/Body/ScenePreview/CenterContainer
@onready var scene_key_input: TextEdit = $Root/Header/SceneKeyInput
@onready var root: VBoxContainer = $Root

func _ready() -> void:
	if grid_overlay:
		grid_overlay.tilemap_layer_changed.connect(on_tilemap_layer_changed)
		grid_overlay.editor_property_changed.connect(show_pannel_preview)
		grid_overlay.enabled_changed.connect(on_enabled_changed)
		on_enabled_changed(grid_overlay.enabled)
	
	if Engine.is_editor_hint():
		scene_picker = EditorResourcePicker.new()
		scene_picker.custom_minimum_size = Vector2(150, 5)
		scene_picker.base_type = "PackedScene"
		scene_picker.custom_minimum_size = scene_loader_container.custom_minimum_size
		scene_picker.resource_changed.connect(on_scene_picker_resource_changed)
		scene_loader_container.add_child(scene_picker)
		scene_picker.show()

func on_scene_picker_resource_changed(_res: PackedScene) -> void:
	if scene_picker.edited_resource == null:
		return
	var scene = scene_picker.edited_resource.instantiate()
	grid_overlay.clone_preview(scene)
	grid_overlay.show_preview_node_properties()
	show_pannel_preview()
	scene_picker.edited_resource = null

func on_tilemap_layer_changed(tilemap_layer: SceneTileMapLayer) -> void:
	if tilemap_layer == null or tilemap_layer.tileset == null:
		return
	show_scenes_list()
	show_pannel_preview()

func on_enabled_changed(enabled: bool) -> void:
	if enabled:
		root.visible = true
		show_scenes_list()
		show_pannel_preview()
	else:
		root.visible = false
		remove_children(scene_preview)

func remove_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)

func show_scenes_list() -> void:
	const PANNEL_ROW = preload("uid://bleq38aow0js")
	remove_children(scenes_list)
	for key in grid_overlay.tilemap_layer.tileset.scenes_list():
		var scene: SceneTileMapPannelRow = PANNEL_ROW.instantiate()
		scene.key = key
		scenes_list.add_child(scene)
		scene.use_clicked.connect(use_scene)
		scene.delete_clicked.connect(delete_scene)

func use_scene(key: String) -> void:
	grid_overlay.select_scene_by_key(key)
	show_pannel_preview()

func show_pannel_preview() -> void:
	remove_children(scene_preview)
	if grid_overlay.preview_node == null:
		return
	var scene = grid_overlay.preview_node.duplicate()
	if scene.get_parent():
		scene.get_parent().remove_child(scene)
	scene.visible = true
	scene_preview.add_child(scene)
	scene.position = Vector2.ZERO

func delete_scene(key: String) -> void:
	grid_overlay.tilemap_layer.tileset.scene_erase(key)
	show_scenes_list()

func _on_draw_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.DRAW)

func _on_select_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.SELECT)

func _on_add_btn_pressed() -> void:
	var key: String = scene_key_input.text
	if not grid_overlay.add_scene_to_tileset(key, grid_overlay.preview_node):
		return
	show_scenes_list()
	scene_picker.edited_resource = null
	scene_key_input.text = ''

func _on_scene_key_text_changed() -> void:
	if '\n' in scene_key_input.text:
		scene_key_input.text = scene_key_input.text.split('\n')[0]
		_on_add_btn_pressed()
