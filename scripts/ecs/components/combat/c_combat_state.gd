## C_CombatState
##
## [b]Pure-data[/b] ECS component tracking the current combat posture of an entity.
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Whether an entity [i]can[/i] fire or melee is evaluated by CombatSystem
## reading these fields directly:
## [codeblock]
## # In CombatSystem:
## var can_fire  = combat.ammo_current > 0
##                 and combat.fire_cooldown  <= 0.0
##                 and not combat.is_reloading
## var can_melee = combat.melee_cooldown <= 0.0
## [/codeblock]
##
## All weapon references use ResourceLocation strings (GDD §2).
## Applied to: Player ECS bridge, Human Enemies, Non-Human Enemies.
class_name C_CombatState
extends Component

## ResourceLocation string of the currently equipped weapon item.
## Empty string = no weapon equipped (unarmed / default melee).
@export var equipped_weapon_id: String = ""

## Rounds remaining in the current magazine.
@export var ammo_current: int = 0
## Full magazine capacity for the equipped weapon.
@export var ammo_max: int = 0

## [code]true[/code] while the entity is actively aiming.
## CombatSystem uses this to reduce bullet spread.
@export var is_aiming: bool = false
## [code]true[/code] while the fire input is held.
@export var wants_fire: bool = false

## Seconds until the next ranged shot is allowed. Decremented by CombatSystem.
@export var fire_cooldown: float = 0.0

## Seconds until the next melee strike is allowed. Decremented by CombatSystem.
@export var melee_cooldown: float = 0.0

## Entity ID string of the current attack target (AI enemies only).
## Empty string = no current target.
@export var target_entity_id: String = ""

## [code]true[/code] while a reload action is in progress.
@export var is_reloading: bool = false
## Reload progress (0–1). Written by CombatSystem each frame during reload.
@export var reload_progress: float = 0.0

## Recoil accumulator used by CombatSystem to increase spread during sustained fire.
@export var recoil_accum: float = 0.0
## Degrees of base hip-fire spread (no recoil modifier).
@export var hipfire_spread_deg: float = 6.0
## Degrees of base ADS spread (no recoil modifier).
@export var ads_spread_deg: float = 1.5
## Added spread in degrees per 1.0 recoil_accum.
@export var recoil_spread_per_accum_deg: float = 2.0
## Recoil accumulated per fired shot.
@export var recoil_per_shot: float = 0.6
## Recoil recovery per second.
@export var recoil_recovery_per_sec: float = 2.0


## Convenience constructor. All fields start at safe defaults.
## Usage: [code]C_CombatState.new()[/code]
func _init() -> void:
	pass
