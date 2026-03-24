## C_ProjectileData
##
## [b]Pure-data[/b] ECS component storing all runtime state for a single
## projectile entity (GDD §6.3, Tech Stack §5.3).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## The ProjectileSystem is responsible for:
##   • Advancing [member age] by delta each frame.
##   • Moving the projectile using [member velocity].
##   • Performing hit detection (raycasts or grid queries).
##   • Calling the entity's [method BaseProjectile.on_hit] / [method BaseProjectile.on_expire]
##     callbacks at the appropriate time.
##   • Queuing projectile removal via [code]cmd.remove_entity(entity)[/code].
##
## Applied to: BaseProjectile and all subclasses.
class_name C_ProjectileData
extends Component

const DEFAULT_SPRITE_PATH := "res://assets/game/textures/projectiles/bullet.png"

## Travel velocity in pixels per second. Computed at spawn from direction × speed.
@export var velocity: Vector2 = Vector2.ZERO

## Scalar speed used to rebuild [member velocity] from a direction vector.
@export var speed: float = 600.0
## Original speed at spawn for distance attenuation curve.
@export var base_speed: float = 600.0
## Remaining travel distance in pixels before this projectile expires.
@export var remaining_distance: float = 1400.0
## Original max distance used to compute distance-based decay.
@export var max_distance: float = 1400.0

## Flat damage applied on first valid hit.
@export var damage: float = 20.0
## Original damage at spawn for distance attenuation curve.
@export var base_damage: float = 20.0

## Armor penetration value compared against the target's armor rating.
## Excess penetration above the armor value converts to a damage bonus.
@export var penetration: float = 0.0

## Maximum travel time in seconds before auto-expiry.
@export var lifetime: float = 2.0

## Seconds elapsed since this projectile was spawned. Incremented by ProjectileSystem.
@export var age: float = 0.0

## Entity ID string of the entity that fired this projectile.
## Used to prevent self-hit and to attribute kill credit.
@export var owner_entity_id: String = ""

## ResourceLocation string of the source weapon item (e.g. [code]"game:item_weapon"[/code]).
## Used to look up fire-mode and caliber tags in the registry.
@export var weapon_id: String = ""

## Set to [code]true[/code] by ProjectileSystem after the first collision,
## preventing double-hit processing before the entity is queued for removal.
@export var has_hit: bool = false
## Shot spread deviation in radians applied at spawn from aim direction.
@export var spread_deviation_rad: float = 0.0
## Projectile sprite path used to derive collision radius.
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var sprite_path: String = DEFAULT_SPRITE_PATH
## Collision radius derived from the projectile sprite bounds.
@export var collision_radius: float = 4.0


## Convenience constructor.
## Usage: [code]C_ProjectileData.new(600.0, 20.0, 0.0, 2.0)[/code]
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
	var normalized := path
	if normalized.is_empty():
		normalized = DEFAULT_SPRITE_PATH
	sprite_path = normalized
	collision_radius = _compute_collision_radius_from_sprite(normalized)


func _compute_collision_radius_from_sprite(path: String) -> float:
	if not ResourceLoader.exists(path):
		return 4.0
	var texture := load(path)
	if texture is Texture2D:
		var size := texture.get_size()
		if size.x > 0.0 and size.y > 0.0:
			return maxf(1.0, maxf(size.x, size.y) * 0.5)
	return 4.0
