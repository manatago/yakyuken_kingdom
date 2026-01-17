extends Control

@export var text: String = "":
	set(value):
		text = value
		if $Label:
			$Label.text = value
			_update_size()

@export var is_left: bool = true: # True for left character (tail points left), False for right
	set(value):
		is_left = value
		queue_redraw()

@export var bg_color: Color = Color.WHITE
@export var border_color: Color = Color(0.6, 0.6, 0.6)
@export var border_width: float = 2.0
@export var padding: Vector2 = Vector2(20, 20)
@export var tail_size: Vector2 = Vector2(20, 20)

func _ready():
	$Label.text = text
	_update_size()

func _update_size():
	# Resize label and this control based on text
	var label_size = $Label.get_minimum_size()
	custom_minimum_size = label_size + padding * 2
	size = custom_minimum_size
	queue_redraw()

func _draw():
	var rect = Rect2(Vector2.ZERO, size)
	var radius = 20.0

	# Draw rounded bubble body (Fill + Border)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bg_color
	style_box.border_color = border_color
	style_box.set_border_width_all(int(border_width))
	style_box.set_corner_radius_all(int(radius))
	style_box.draw(get_canvas_item(), rect)

	# Draw tail
	var tail_points = PackedVector2Array()
	var tail_base_y = size.y / 2
	var overlap_offset = border_width  # Overlap to cover the border line

	if is_left:
		# Tail on the left side
		# Base points moved inward by overlap_offset
		tail_points.append(Vector2(overlap_offset, tail_base_y - tail_size.y / 2))
		tail_points.append(Vector2(-tail_size.x, tail_base_y))
		tail_points.append(Vector2(overlap_offset, tail_base_y + tail_size.y / 2))
	else:
		# Tail on the right side
		# Base points moved inward by overlap_offset
		tail_points.append(Vector2(size.x - overlap_offset, tail_base_y - tail_size.y / 2))
		tail_points.append(Vector2(size.x + tail_size.x, tail_base_y))
		tail_points.append(Vector2(size.x - overlap_offset, tail_base_y + tail_size.y / 2))

	# Draw filled tail (covers the border seam)
	draw_colored_polygon(tail_points, bg_color)

	# Draw tail border (lines)
	# We only draw the two outer edges of the triangle
	if is_left:
		draw_line(Vector2(overlap_offset, tail_base_y - tail_size.y / 2), Vector2(-tail_size.x, tail_base_y), border_color, border_width)
		draw_line(Vector2(-tail_size.x, tail_base_y), Vector2(overlap_offset, tail_base_y + tail_size.y / 2), border_color, border_width)
	else:
		draw_line(Vector2(size.x - overlap_offset, tail_base_y - tail_size.y / 2), Vector2(size.x + tail_size.x, tail_base_y), border_color, border_width)
		draw_line(Vector2(size.x + tail_size.x, tail_base_y), Vector2(size.x - overlap_offset, tail_base_y + tail_size.y / 2), border_color, border_width)

