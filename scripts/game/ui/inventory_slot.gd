class_name InventorySlot
extends TextureRect
## Visual representation of a single inventory grid cell.
## Uses inventory_item.png as base texture.
## Draws a light white-gray overlay when occupied.

const SLOT_SIZE := 64
const OCCUPIED_OVERLAY_COLOR := Color(1.0, 1.0, 1.0, 0.18)

var grid_x: int = 0
var grid_y: int = 0
var is_occupied: bool = false

func _init(gx: int = 0, gy: int = 0) -> void:
	grid_x = gx
	grid_y = gy
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

func setup(slot_texture: Texture2D) -> void:
	texture = slot_texture

func set_occupied(occupied: bool) -> void:
	is_occupied = occupied
	queue_redraw()

func _draw() -> void:
	if is_occupied:
		draw_rect(Rect2(Vector2.ZERO, size), OCCUPIED_OVERLAY_COLOR)
