class_name GridOverlay
extends Control

const MAX_LINES = 100

var editor_plugin: EditorPlugin
var grid_size: Vector2
var grid_color: Color
var line_width: int

var enabled := false

func _init(editor_plugin_: EditorPlugin, grid_size_: Vector2, grid_color_: Color, line_width_: int):
	editor_plugin = editor_plugin_
	grid_size = grid_size_
	grid_color = grid_color_
	line_width = line_width_

func _ready():
	set_process(true)
	set_mouse_filter(MOUSE_FILTER_IGNORE)

func _process(delta):
	queue_redraw()

func _draw():
	if not enabled:
		return

	draw_grid(
		get_viewport_rect().size,
		EditorInterface.get_editor_viewport_2d().global_canvas_transform,
	)

func draw_grid(size: Vector2, transform: Transform2D):
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
