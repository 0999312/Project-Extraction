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

enum FireMode {
	SAFE,
	SEMI,
	AUTO,
}

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
## [code]true[/code] on the frame a reload action is requested.
@export var wants_reload: bool = false
## [code]true[/code] on the frame fire mode switch is requested.
@export var wants_fire_mode_toggle: bool = false
## Previous frame fire input state for fire-mode edge handling.
@export var was_fire_pressed_last_frame: bool = false

## Seconds until the next ranged shot is allowed. Decremented by CombatSystem.
@export var fire_cooldown: float = 0.0
## Seconds between shots for AUTO/SEMI firing.
@export var fire_interval: float = 0.14

## Seconds until the next melee strike is allowed. Decremented by CombatSystem.
@export var melee_cooldown: float = 0.0

## Entity ID string of the current attack target (AI enemies only).
## Empty string = no current target.
@export var target_entity_id: String = ""

## [code]true[/code] while a reload action is in progress.
@export var is_reloading: bool = false
## Reload progress (0–1). Written by CombatSystem each frame during reload.
@export var reload_progress: float = 0.0
## Reload duration in seconds.
@export var reload_duration_sec: float = 1.5
## Empty-mag reminder SFX cooldown to avoid audio spam.
@export var empty_mag_sfx_cooldown: float = 0.0

## Current fire mode (safe / semi / auto).
@export var fire_mode: FireMode = FireMode.SEMI

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

## Weapon attack damage per projectile.
@export var attack_damage: float = 20.0
## Weapon projectile speed (pixels per second).
@export var projectile_speed: float = 850.0
## Weapon projectile maximum travel distance (pixels).
@export var projectile_max_distance: float = 1400.0
## Projectile armor penetration value.
@export var projectile_penetration: float = 0.0
## Projectile life upper bound (seconds).
@export var projectile_lifetime: float = 2.0
## Projectile sprite path used by spawned projectiles for collision sizing.
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var projectile_sprite_path: String = "res://assets/game/textures/projectiles/bullet.png"
## Aim camera offset distance while ADS.
@export var ads_distance: float = 170.0
## Number of projectiles emitted per single shot.
@export var pellets_per_shot: int = 1


## Convenience constructor. All fields start at safe defaults.
## Usage: [code]C_CombatState.new()[/code]
func _init() -> void:
	pass
