class_name CrosshairNode
extends Sprite2D

enum Mode {
	RELAXED,
	HIP_FIRE,
	ADS,
}

const MOUSE_TEXTURE_PATH := "res://assets/game/textures/ui/mouse.png"
const HIP_FIRE_TEXTURE_PATH := "res://assets/game/textures/ui/crosshair_normal.png"
const ADS_TEXTURE_PATH := "res://assets/game/textures/ui/crosshair_aiming.png"
const AIM_DISTANCE_EPSILON := 0.0001

var mode: Mode = Mode.RELAXED
var _mouse_texture: Texture2D = null
var _hip_fire_texture: Texture2D = null
var _ads_texture: Texture2D = null

func _ready() -> void:
	top_level = true
	z_index = 1024
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_textures()
	set_mode(Mode.RELAXED)

func _process(_delta: float) -> void:
	if get_tree().paused:
		texture = _mouse_texture
		centered = false
		global_position = get_global_mouse_position()
		return
	if mode == Mode.RELAXED:
		global_position = get_global_mouse_position()

func set_mode(next_mode: Mode) -> void:
	mode = next_mode
	match mode:
		Mode.RELAXED:
			texture = _mouse_texture
			centered = false
		Mode.HIP_FIRE:
			texture = _hip_fire_texture
			centered = true
		Mode.ADS:
			texture = _ads_texture
			centered = true

func update_position(player_position: Vector2, aiming: bool, max_aim_distance: float) -> void:
	var mouse_pos := get_global_mouse_position()
	if mode == Mode.RELAXED:
		global_position = mouse_pos
		return
	var to_mouse := mouse_pos - player_position
	var max_distance := maxf(0.0, max_aim_distance)
	if aiming and max_distance > 0.0 and to_mouse.length_squared() > AIM_DISTANCE_EPSILON:
		global_position = player_position + to_mouse.limit_length(max_distance)
		return
	global_position = mouse_pos

func get_effective_aim_direction(fallback_origin: Vector2, fallback_direction: Vector2) -> Vector2:
	var to_crosshair := global_position - fallback_origin
	if to_crosshair.length_squared() > AIM_DISTANCE_EPSILON:
		return to_crosshair.normalized()
	if fallback_direction.length_squared() > AIM_DISTANCE_EPSILON:
		return fallback_direction.normalized()
	return Vector2.RIGHT

func _load_textures() -> void:
	_mouse_texture = _load_texture(MOUSE_TEXTURE_PATH)
	_hip_fire_texture = _load_texture(HIP_FIRE_TEXTURE_PATH)
	_ads_texture = _load_texture(ADS_TEXTURE_PATH)

func _load_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		push_warning("CrosshairNode texture file not found: %s" % path)
		return null
	var loaded := load(path)
	if loaded is Texture2D:
		return loaded as Texture2D
	push_warning("CrosshairNode texture is not a Texture2D resource: %s" % path)
	return null
