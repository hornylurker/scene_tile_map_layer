@tool
extends Control
class_name SceneTileMapPannelRow

signal delete_clicked(String)
signal use_clicked(String)
signal use_rename(String)

@export var key: String

@onready var label: Label = $MarginContainer/SceneTemplate/Label

func _ready() -> void:
	label.text = key

func _on_button_pressed() -> void:
	delete_clicked.emit(key)

func _on_use_btn_pressed() -> void:
	use_clicked.emit(key)

func _on_rename_btn_pressed() -> void:
	use_rename.emit(key)
