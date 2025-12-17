@tool
extends Resource
class_name SceneTileSet

@export var props: Dictionary[String, Variant] = {}
@export var paths: Dictionary[String, String] = {}

func scene_add(key: String, node: Node2D) -> bool:
	if key == '':
		push_warning("Can't add key '' to tileset. Specify real name.")
		return false
	if key in props:
		push_warning("Can't add key duplicated '%s' to tileset." % key)
		return false
	if node == null:
		push_warning("Can't add scene <null> to tileset. Select or load it first.")
		return false
	props[key] = get_all_properties(node)
	paths[key] = node.scene_file_path
	return true

func _scene_get(key: String) -> PackedScene:
	var scene: PackedScene = load(paths[key])
	return scene

func scene_get_instance(key) -> Node2D:
	var scene := _scene_get(key)
	var node = scene.instantiate()
	for prop in props[key]:
		node.set(prop, props[key][prop])
	return node
	

func scene_erase(key: String):
	props.erase(key)
	paths.erase(key)

func scenes_list() -> Array[String]:
	return props.keys()

func get_all_properties(node: Node) -> Dictionary:
	var props := node.get_property_list()
	var result := {}
	for p in props:
		var name: String = p.name
		if name in ["script", "owner", "scene_file_path", "multiplayer", "process_mode"]:
			continue
		if not (p.usage & PROPERTY_USAGE_STORAGE):
			continue
		var value = node.get(name)
		result[name] = value
	return result
