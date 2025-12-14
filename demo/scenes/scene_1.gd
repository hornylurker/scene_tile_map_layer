@tool
extends Node2D
class_name Scene1

@export var color: Color = Color.WHITE:
	get():
		return color
	set(value):
		color = value
		if sprite_2d:
			sprite_2d.modulate = value

@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready():
	sprite_2d.modulate = color
