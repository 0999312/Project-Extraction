## C_CombatState
##
## ECS component tracking the current combat posture of an entity.
## Shared by the Player (via the ECS bridge entity) and all enemies.
##
## Weapon switching and reload logic are handled by dedicated systems
## that read and write this component.  All item references use
## ResourceLocation strings (GDD §2, e.g. "game:item_weapon").
class_name C_CombatState
extends Component

## ResourceLocation string of the currently equipped weapon item.
## Empty string means no weapon equipped (fists / melee default).
@export var equipped_weapon_id: String = ""

## Rounds remaining in the current magazine.
@export var ammo_current: int = 0
## Full magazine capacity for the equipped weapon.
@export var ammo_max: int = 0

## True while the entity is actively aiming (affects spread and speed).
@export var is_aiming: bool = false

## Seconds remaining before the next ranged shot is allowed (fire rate gate).
@export var fire_cooldown: float = 0.0

## Seconds remaining before the next melee strike is allowed.
@export var melee_cooldown: float = 0.0

## Entity ID string of the current attack target (enemies only; empty for Player).
@export var target_entity_id: String = ""

## True while a reload action is in progress.
@export var is_reloading: bool = false
## Progress of an ongoing reload action (0–1).
@export var reload_progress: float = 0.0


## Returns true if the entity can fire right now (has ammo and cooldown expired).
func can_fire() -> bool:
	return ammo_current > 0 and fire_cooldown <= 0.0 and not is_reloading


## Returns true if the entity can perform a melee strike right now.
func can_melee() -> bool:
	return melee_cooldown <= 0.0
