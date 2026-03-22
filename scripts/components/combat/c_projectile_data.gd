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

## Travel velocity in pixels per second. Computed at spawn from direction × speed.
@export var velocity: Vector2 = Vector2.ZERO

## Scalar speed used to rebuild [member velocity] from a direction vector.
@export var speed: float = 600.0

## Flat damage applied on first valid hit.
@export var damage: float = 20.0

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


## Convenience constructor.
## Usage: [code]C_ProjectileData.new(600.0, 20.0, 0.0, 2.0)[/code]
func _init(spd: float = 600.0, dmg: float = 20.0, pen: float = 0.0, life: float = 2.0) -> void:
	speed = spd
	damage = dmg
	penetration = pen
	lifetime = life
