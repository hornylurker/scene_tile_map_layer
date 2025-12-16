@tool
class_name SceneTileMapPannel
extends Control

@onready var grid_overlay: GridOverlay
@onready var header: HBoxContainer = $VBoxContainer/Header
@onready var scenes_list: VBoxContainer = $VBoxContainer/Body/ScenesPanel/ScenesList
var scene_picker: EditorResourcePicker
@onready var scene_loader_container: Control = $VBoxContainer/Body/ScenesPanel/Buttons/SceneLoaderContainer
@onready var scene_preview: Control = $VBoxContainer/Body/ScenePreview/CenterContainer
@onready var scene_key_input: TextEdit = $VBoxContainer/Body/ScenesPanel/Buttons/SceneKeyInput

func _ready() -> void:
	if grid_overlay:
		grid_overlay.tilemap_layer_changed.connect(on_tilemap_layer_changed)
	
	if Engine.is_editor_hint():
		scene_picker = EditorResourcePicker.new()
		scene_picker.custom_minimum_size = Vector2(150, 5)
		scene_picker.base_type = "PackedScene"
		scene_picker.custom_minimum_size = scene_loader_container.custom_minimum_size
		scene_loader_container.add_child(scene_picker)
		scene_picker.show()

func on_tilemap_layer_changed(tilemap_layer: SceneTileMapLayer) -> void:
	if tilemap_layer == null:
		return
	show_scenes_list()

func show_scenes_list():
	const PANNEL_ROW = preload("uid://bleq38aow0js")
	for child in scenes_list.get_children():
		scenes_list.remove_child(child)
	for key in grid_overlay.tilemap_layer.tileset:
		var scene: SceneTileMapPannelRow = PANNEL_ROW.instantiate()
		scene.key = key
		scenes_list.add_child(scene)
		scene.use_clicked.connect(use_scene)
		scene.delete_clicked.connect(delete_scene)

func use_scene(key: String):
	grid_overlay.select_scene_by_key(key)

func show_preview():
	return
	var scene = grid_overlay.preview_node.duplicate()
	if scene.get_parent():
		scene.get_parent().remove_child(scene)
	scene_preview.add_child(scene)
	
func delete_scene(key: String):
	grid_overlay.tilemap_layer.tileset.erase(key)
	show_scenes_list()

func _on_draw_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.DRAW)

func _on_select_pressed() -> void:
	grid_overlay.set_mode(GridOverlay.Mode.SELECT)

func _on_add_btn_pressed() -> void:
	var scene: PackedScene = scene_picker.edited_resource
	var key: String = scene_key_input.text if scene_key_input.text != '' else scene.resource_path
	grid_overlay.tilemap_layer.tileset[key] = scene
	show_scenes_list()
	scene_picker.edited_resource = null

func _on_load_btn_pressed() -> void:
	var scene = scene_picker.edited_resource.instantiate()
	grid_overlay.clone_preview(scene)
	grid_overlay.show_preview_node_properties()
	show_preview()
