class_name S_CombatFireSystem
extends System

const BaseProjectileScript := preload("res://scripts/ecs/projectiles/e_base_projectile.gd")

func setup() -> void:
	randomize()

func query() -> QueryBuilder:
	return q.with_all([C_CombatState, C_AimState, C_Position]).iterate([C_CombatState, C_AimState, C_Position])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var combats: Array = components[0]
	var aims: Array = components[1]
	var positions: Array = components[2]
	for i in entities.size():
		var entity := entities[i]
		var combat: C_CombatState = combats[i]
		var aim: C_AimState = aims[i]
		var pos: C_Position = positions[i]
		combat.fire_cooldown = maxf(0.0, combat.fire_cooldown - delta)
		combat.recoil_accum = maxf(0.0, combat.recoil_accum - combat.recoil_recovery_per_sec * delta)
		if not combat.wants_fire:
			continue
		if combat.ammo_current <= 0:
			continue
		if combat.fire_cooldown > 0.0:
			continue

		var projectile := BaseProjectileScript.new()
		var projectile_pos := C_Position.new(pos.world_position, aim.aim_direction.angle())
		var projectile_data := C_ProjectileData.new(850.0, 20.0, 0.0, 2.0)
		projectile_data.spread_deviation_rad = deg_to_rad(_compute_spread_offset_degrees(combat, aim))
		projectile.add_components([projectile_pos, projectile_data])
		ECS.world.add_entity(projectile)
		projectile.setup(aim.aim_direction, projectile_data.damage, projectile_data.penetration, entity.id, combat.equipped_weapon_id)

		combat.ammo_current -= 1
		combat.fire_cooldown = 0.14
		combat.recoil_accum += combat.recoil_per_shot


func _compute_spread_offset_degrees(combat: C_CombatState, aim: C_AimState) -> float:
	var base_spread := combat.ads_spread_deg if combat.is_aiming else combat.hipfire_spread_deg
	base_spread += combat.recoil_accum * combat.recoil_spread_per_accum_deg
	base_spread *= maxf(0.01, aim.precision_multiplier)
	return randf_range(-base_spread, base_spread)


func deps() -> Dictionary:
	return {
		Runs.After: [],
		Runs.Before: [S_ProjectileMotionSystem],
	}
