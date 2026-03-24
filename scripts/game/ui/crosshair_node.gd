class_name CrosshairNode
extends Sprite2D

enum Mode {
	RELAXED,
	HIP_FIRE,
	ADS,
}

const AIM_DISTANCE_EPSILON := 0.0001
const UI_Z_INDEX := 1024
const HIP_FIRE_TEXTURE := preload("res://assets/game/textures/ui/crosshair_normal.png")
const ADS_TEXTURE := preload("res://assets/game/textures/ui/crosshair_aiming.png")

var mode: Mode = Mode.RELAXED
var _hip_fire_texture: Texture2D = null
var _ads_texture: Texture2D = null

func _ready() -> void:
	top_level = true
	z_index = UI_Z_INDEX
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_textures()
	set_mode(Mode.RELAXED)

func _process(_delta: float) -> void:
	if get_tree().paused:
		if mode != Mode.RELAXED:
			set_mode(Mode.RELAXED)
	if get_tree().paused or mode == Mode.RELAXED:
		global_position = get_global_mouse_position()

func set_mode(next_mode: Mode) -> void:
	mode = next_mode
	match mode:
		Mode.RELAXED:
			visible = false
		Mode.HIP_FIRE:
			visible = true
			texture = _hip_fire_texture
			centered = true
		Mode.ADS:
			visible = true
			texture = _ads_texture
			centered = true

func update_position(_player_position: Vector2, _aiming: bool, _max_aim_distance: float) -> void:
	global_position = get_global_mouse_position()

func get_effective_aim_direction(origin_position: Vector2, fallback_direction: Vector2) -> Vector2:
	var to_crosshair := global_position - origin_position
	if to_crosshair.length_squared() > AIM_DISTANCE_EPSILON:
		return to_crosshair.normalized()
	if fallback_direction.length_squared() > AIM_DISTANCE_EPSILON:
		return fallback_direction.normalized()
	return Vector2.RIGHT

func _load_textures() -> void:
	_hip_fire_texture = HIP_FIRE_TEXTURE
	_ads_texture = ADS_TEXTURE
