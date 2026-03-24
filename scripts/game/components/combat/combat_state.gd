class_name CombatState
extends Resource

const DEFAULT_PROJECTILE_DEFINITION_ID := "game:projectile/bullet"

enum FireMode {
	SAFE,
	SEMI,
	AUTO,
}

@export var equipped_weapon_id: String = ""
@export var ammo_current: int = 0
@export var ammo_max: int = 0
@export var is_aiming: bool = false
@export var wants_fire: bool = false
@export var wants_reload: bool = false
@export var wants_fire_mode_toggle: bool = false
@export var was_fire_pressed_last_frame: bool = false
@export var fire_cooldown: float = 0.0
@export var fire_interval: float = 0.14
@export var melee_cooldown: float = 0.0
@export var target_actor_id: String = ""
@export var is_reloading: bool = false
@export var reload_progress: float = 0.0
@export var reload_duration_sec: float = 1.5
@export var empty_mag_sfx_cooldown: float = 0.0
@export var fire_mode: FireMode = FireMode.SEMI
@export var recoil_accum: float = 0.0
@export var hipfire_spread_deg: float = 6.0
@export var ads_spread_deg: float = 1.5
@export var recoil_spread_per_accum_deg: float = 2.0
@export var recoil_per_shot: float = 0.6
@export var recoil_recovery_per_sec: float = 2.0
@export var projectile_definition_id: String = DEFAULT_PROJECTILE_DEFINITION_ID
@export var ads_distance: float = 170.0
@export var pellets_per_shot: int = 1

func _init() -> void:
	pass
