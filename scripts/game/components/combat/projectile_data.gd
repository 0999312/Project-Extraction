class_name ProjectileData
extends Resource

const DEFAULT_SPRITE_PATH := "res://assets/game/textures/projectiles/bullet.png"
const DEFAULT_PROJECTILE_TEXTURE := preload("res://assets/game/textures/projectiles/bullet.png")
const COLLISION_LAYER_AIR := 1 << 2
const COLLISION_MASK_HIT_AND_AIR := (1 << 0) | (1 << 2)
static var _collision_radius_cache: Dictionary = {}

@export var velocity: Vector2 = Vector2.ZERO
@export var speed: float = 600.0
@export var base_speed: float = 600.0
@export var remaining_distance: float = 1400.0
@export var max_distance: float = 1400.0
@export var damage: float = 20.0
@export var base_damage: float = 20.0
@export var penetration: float = 0.0
@export var lifetime: float = 2.0
@export var age: float = 0.0
@export var owner_actor_id: String = ""
@export var weapon_id: String = ""
@export var has_hit: bool = false
@export var spread_deviation_rad: float = 0.0
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var sprite_path: String = DEFAULT_SPRITE_PATH
@export var collision_radius: float = 4.0
@export var collision_layer: int = COLLISION_LAYER_AIR
@export var collision_mask: int = COLLISION_MASK_HIT_AND_AIR

func _init(spd: float = 600.0, dmg: float = 20.0, pen: float = 0.0, life: float = 2.0, max_dist: float = 1400.0) -> void:
	speed = spd
	base_speed = spd
	damage = dmg
	base_damage = dmg
	penetration = pen
	lifetime = life
	max_distance = max_dist
	remaining_distance = max_dist
	configure_sprite(DEFAULT_SPRITE_PATH)

func configure_sprite(path: String) -> void:
	var normalized := path if not path.is_empty() else DEFAULT_SPRITE_PATH
	sprite_path = normalized
	collision_radius = _compute_collision_radius_from_sprite(normalized)

func _compute_collision_radius_from_sprite(path: String) -> float:
	if _collision_radius_cache.has(path):
		return _collision_radius_cache[path]
	if path == DEFAULT_SPRITE_PATH:
		var default_size := DEFAULT_PROJECTILE_TEXTURE.get_size()
		if default_size.x > 0.0 and default_size.y > 0.0:
			var default_radius := maxf(1.0, maxf(default_size.x, default_size.y) * 0.5)
			_collision_radius_cache[path] = default_radius
			return default_radius
	if not ResourceLoader.exists(path):
		_collision_radius_cache[path] = 4.0
		return 4.0
	var texture := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)
	if texture is Texture2D:
		var size : Vector2= texture.get_size()
		if size.x > 0.0 and size.y > 0.0:
			var radius := maxf(1.0, maxf(size.x, size.y) * 0.5)
			_collision_radius_cache[path] = radius
			return radius
	_collision_radius_cache[path] = 4.0
	return 4.0
