## C_ProjectileData
##
## ECS component storing all runtime data for a single projectile entity
## (GDD §6.3, Tech Stack §5.3).
##
## Projectiles are pure ECS entities with no per-bullet scene node.
## The ProjectileSystem updates [member age], moves the projectile using
## [member velocity] and [member speed], performs hit detection via
## raycasts, and calls the projectile entity's [method BaseProjectile.on_hit]
## or [method BaseProjectile.on_expire] as appropriate.
##
## Applied to: BaseProjectile and all subclasses.
class_name C_ProjectileData
extends Component

## Direction × speed vector (pixels per second).  Set at spawn time.
@export var velocity: Vector2 = Vector2.ZERO

## Scalar speed used when velocity is rebuilt from direction (pixels/s).
@export var speed: float = 600.0

## Flat damage dealt on first valid hit.
@export var damage: float = 20.0

## Armor penetration value compared against the target's armor rating.
## Excess penetration (above the armor value) converts to a damage bonus.
@export var penetration: float = 0.0

## Maximum time (seconds) the projectile may travel before auto-expiring.
@export var lifetime: float = 2.0

## Seconds elapsed since this projectile was spawned.
@export var age: float = 0.0

## Entity ID string of the entity that fired this projectile.
## Used to prevent self-hit and to attribute kill credit.
@export var owner_entity_id: String = ""

## ResourceLocation string of the weapon item that produced this projectile
## (e.g. "game:item_weapon").  Used to look up fire-mode and caliber tags.
@export var weapon_id: String = ""

## Set to true by the ProjectileSystem after the first collision.
## Prevents double-hit processing before the entity is queued for removal.
@export var has_hit: bool = false
