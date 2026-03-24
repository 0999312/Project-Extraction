class_name AdsVignetteOverlay
extends CanvasLayer
## Full-screen darkening overlay with a circular transparent hole centered on
## the crosshair during ADS.  The hole matches the crosshair sprite size
## (default 64 × 64 → radius 32 px) so the crosshair remains fully visible
## while the rest of the viewport is dimmed.

const ADS_VIGNETTE_SHADER := preload("res://resources/shaders/ads_vignette.gdshader")

const DEFAULT_RADIUS_PX := 32.0
const DEFAULT_DARKNESS := 0.5
const DEFAULT_SOFTNESS_PX := 4.0

## Whether the vignette effect is enabled.  When disabled the overlay is never
## shown regardless of aiming state.
var enabled: bool = true

## Radius of the transparent circle in viewport pixels.
var radius_px: float = DEFAULT_RADIUS_PX

## Opacity of the darkened area outside the circle (0 = fully transparent,
## 1 = fully opaque black).
var darkness: float = DEFAULT_DARKNESS

## Pixel-width of the soft edge between the transparent hole and the darkened
## area.
var softness_px: float = DEFAULT_SOFTNESS_PX

var _rect: ColorRect = null
var _material: ShaderMaterial = null

func _ready() -> void:
	# Layer 1 renders above the default 2D canvas (layer 0) so the darkening
	# overlay covers the game world.  The crosshair sprite sits inside the
	# transparent hole and remains visible.
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	_rect.visible = false

func _build_overlay() -> void:
	_material = ShaderMaterial.new()
	_material.shader = ADS_VIGNETTE_SHADER
	_material.set_shader_parameter("radius_px", radius_px)
	_material.set_shader_parameter("darkness", darkness)
	_material.set_shader_parameter("softness_px", softness_px)
	_rect = ColorRect.new()
	_rect.name = "VignetteRect"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)

func set_active(active: bool) -> void:
	if _rect == null:
		return
	_rect.visible = active and enabled

func update_center(screen_position: Vector2) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("center_px", screen_position)
