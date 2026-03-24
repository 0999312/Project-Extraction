class_name S_CombatFireSystem
extends System

const BaseProjectileScript := preload("res://scripts/ecs/projectiles/e_base_projectile.gd")
const EMPTY_MAG_SFX_PATH := "res://assets/game/sounds/sounds/mag_empty.mp3"
const SHOOT_SFX_PATH := "res://assets/game/sounds/sounds/handgun_shoot.mp3"
const RELOAD_SFX_PATH := "res://assets/game/sounds/sounds/reload.mp3"
const EMPTY_MAG_SFX_MIN_INTERVAL := 0.35
const AI_RELOAD_FACTIONS := [
	C_Faction.FactionType.HUMAN_ENEMY,
	C_Faction.FactionType.NON_HUMAN_ENEMY,
]

var _shoot_sfx: AudioStream
var _reload_sfx: AudioStream
var _empty_mag_sfx: AudioStream

func setup() -> void:
	randomize()
	_shoot_sfx = load(SHOOT_SFX_PATH)
	_reload_sfx = load(RELOAD_SFX_PATH)
	_empty_mag_sfx = load(EMPTY_MAG_SFX_PATH)

func query() -> QueryBuilder:
	return q.with_all([C_CombatState, C_AimState, C_Position, C_Faction]).iterate([C_CombatState, C_AimState, C_Position, C_Faction])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var combats: Array = components[0]
	var aims: Array = components[1]
	var positions: Array = components[2]
	var faction_components: Array = components[3]
	for i in entities.size():
		var entity := entities[i]
		var combat: C_CombatState = combats[i]
		var aim: C_AimState = aims[i]
		var pos: C_Position = positions[i]
		var faction: C_Faction = faction_components[i]
		combat.fire_cooldown = maxf(0.0, combat.fire_cooldown - delta)
		combat.recoil_accum = maxf(0.0, combat.recoil_accum - combat.recoil_recovery_per_sec * delta)
		combat.empty_mag_sfx_cooldown = maxf(0.0, combat.empty_mag_sfx_cooldown - delta)
		if combat.wants_fire_mode_toggle:
			_cycle_fire_mode(combat)
		if _should_start_reload(combat, faction):
			_start_reload(combat)
		_update_reload_state(combat, delta)
		var should_fire := _is_fire_requested(combat, faction)
		if not should_fire:
			combat.was_fire_pressed_last_frame = combat.wants_fire
			continue
		if combat.is_reloading:
			combat.was_fire_pressed_last_frame = combat.wants_fire
			continue
		if combat.ammo_current <= 0:
			_play_empty_mag_if_needed(combat)
			combat.was_fire_pressed_last_frame = combat.wants_fire
			continue
		if combat.fire_cooldown > 0.0:
			combat.was_fire_pressed_last_frame = combat.wants_fire
			continue

		var pellets := maxi(1, combat.pellets_per_shot)
		for _pellet_index in range(pellets):
			var projectile := BaseProjectileScript.new()
			var projectile_pos := C_Position.new(pos.world_position, aim.aim_direction.angle())
			var projectile_data := C_ProjectileData.new(
				combat.projectile_speed,
				combat.attack_damage,
				combat.projectile_penetration,
				combat.projectile_lifetime,
				combat.projectile_max_distance
			)
			projectile_data.configure_sprite(combat.projectile_sprite_path)
			projectile_data.spread_deviation_rad = deg_to_rad(_compute_spread_offset_degrees(combat, aim))
			projectile.add_components([projectile_pos, projectile_data])
			ECS.world.add_entity(projectile)
			projectile.setup(aim.aim_direction, projectile_data.damage, projectile_data.penetration, entity.id, combat.equipped_weapon_id)

		combat.ammo_current -= 1
		combat.fire_cooldown = combat.fire_interval
		combat.recoil_accum += combat.recoil_per_shot
		combat.was_fire_pressed_last_frame = combat.wants_fire
		_play_shoot_sfx()
		print("[DEBUG][CombatFire] Entity=%s FIRED | mode=%s ammo=%d/%d recoil=%.2f spread_deg=%.1f aim=(%.2f,%.2f)" % [
			entity.name, C_CombatState.FireMode.keys()[combat.fire_mode],
			combat.ammo_current, combat.ammo_max, combat.recoil_accum,
			combat.hipfire_spread_deg if not combat.is_aiming else combat.ads_spread_deg,
			aim.aim_direction.x, aim.aim_direction.y])
		if combat.ammo_current <= 0:
			_play_empty_mag_if_needed(combat)


func _compute_spread_offset_degrees(combat: C_CombatState, aim: C_AimState) -> float:
	var base_spread := combat.ads_spread_deg if combat.is_aiming else combat.hipfire_spread_deg
	base_spread += combat.recoil_accum * combat.recoil_spread_per_accum_deg
	base_spread *= maxf(0.01, aim.precision_multiplier)
	return randf_range(-base_spread, base_spread)


func _should_start_reload(combat: C_CombatState, faction: C_Faction) -> bool:
	if combat.is_reloading:
		return false
	if combat.ammo_max <= 0:
		return false
	if combat.ammo_current >= combat.ammo_max:
		return false
	if faction.faction in AI_RELOAD_FACTIONS and combat.ammo_current <= 0:
		return true
	return combat.wants_reload and combat.ammo_current < combat.ammo_max


func _start_reload(combat: C_CombatState) -> void:
	combat.is_reloading = true
	combat.reload_progress = 0.0
	_play_reload_sfx()
	print("[DEBUG][CombatFire] RELOAD started | ammo=%d/%d" % [combat.ammo_current, combat.ammo_max])


func _update_reload_state(combat: C_CombatState, delta: float) -> void:
	if not combat.is_reloading:
		return
	var duration := maxf(0.01, combat.reload_duration_sec)
	combat.reload_progress = clampf(combat.reload_progress + delta / duration, 0.0, 1.0)
	if combat.reload_progress >= 1.0:
		combat.ammo_current = combat.ammo_max
		combat.is_reloading = false
		combat.reload_progress = 0.0
		print("[DEBUG][CombatFire] RELOAD complete | ammo=%d/%d" % [combat.ammo_current, combat.ammo_max])


func _is_fire_requested(combat: C_CombatState, faction: C_Faction) -> bool:
	if combat.fire_mode == C_CombatState.FireMode.SAFE:
		return false
	if combat.fire_mode == C_CombatState.FireMode.AUTO:
		return combat.wants_fire
	if faction.faction == C_Faction.FactionType.PLAYER:
		return combat.wants_fire and not combat.was_fire_pressed_last_frame
	return combat.wants_fire


func _cycle_fire_mode(combat: C_CombatState) -> void:
	var prev_mode := combat.fire_mode
	match combat.fire_mode:
		C_CombatState.FireMode.SAFE:
			combat.fire_mode = C_CombatState.FireMode.SEMI
		C_CombatState.FireMode.SEMI:
			combat.fire_mode = C_CombatState.FireMode.AUTO
		_:
			combat.fire_mode = C_CombatState.FireMode.SAFE
	print("[DEBUG][CombatFire] FIRE_MODE changed | %s → %s" % [
		C_CombatState.FireMode.keys()[prev_mode],
		C_CombatState.FireMode.keys()[combat.fire_mode]])


func _play_empty_mag_if_needed(combat: C_CombatState) -> void:
	if combat.empty_mag_sfx_cooldown > 0.0:
		return
	if _empty_mag_sfx != null:
		SoundManager.play_sound(_empty_mag_sfx)
	combat.empty_mag_sfx_cooldown = EMPTY_MAG_SFX_MIN_INTERVAL
	print("[DEBUG][CombatFire] EMPTY_MAG sfx played")


func _play_shoot_sfx() -> void:
	if _shoot_sfx != null:
		SoundManager.play_sound(_shoot_sfx)


func _play_reload_sfx() -> void:
	if _reload_sfx != null:
		SoundManager.play_sound(_reload_sfx)


func deps() -> Dictionary:
	return {
		Runs.After: [],
		Runs.Before: [S_ProjectileMotionSystem],
	}
