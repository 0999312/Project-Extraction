class_name InventorySlot
extends PanelContainer
## Visual representation of a single inventory grid cell.
## Uses StyleBoxFlat (no texture) — 6 px black border, 0 px corner radius.
## Draws a light overlay when occupied.

const SLOT_SIZE := 64
const BG_COLOR := Color(0.0, 0.0, 0.0, 64.0 / 255.0)     # alpha = 64
const BORDER_COLOR := Color(0.0, 0.0, 0.0, 1.0)            # pure black
const BORDER_WIDTH := 6
const CORNER_RADIUS := 0
const OCCUPIED_OVERLAY_COLOR := Color(1.0, 1.0, 1.0, 0.18)

var grid_x: int = 0
var grid_y: int = 0
var is_occupied: bool = false

func _init(gx: int = 0, gy: int = 0) -> void:
	grid_x = gx
	grid_y = gy
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG_COLOR
	sb.border_width_left = BORDER_WIDTH
	sb.border_width_top = BORDER_WIDTH
	sb.border_width_right = BORDER_WIDTH
	sb.border_width_bottom = BORDER_WIDTH
	sb.border_color = BORDER_COLOR
	sb.corner_radius_top_left = CORNER_RADIUS
	sb.corner_radius_top_right = CORNER_RADIUS
	sb.corner_radius_bottom_right = CORNER_RADIUS
	sb.corner_radius_bottom_left = CORNER_RADIUS
	add_theme_stylebox_override("panel", sb)

func setup(_slot_texture: Texture2D) -> void:
	pass

func set_occupied(occupied: bool) -> void:
	is_occupied = occupied
	queue_redraw()

func _draw() -> void:
	if is_occupied:
		draw_rect(Rect2(Vector2.ZERO, size), OCCUPIED_OVERLAY_COLOR)
