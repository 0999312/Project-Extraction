class_name S_ProjectileMotionSystem
extends System

const PROJECTILE_RADIUS_SCALE := 0.75

func query() -> QueryBuilder:
	return q.with_all([C_ProjectileData, C_Position]).iterate([C_ProjectileData, C_Position])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var projectiles: Array = components[0]
	var positions: Array = components[1]
	var candidate_entities := _get_collision_candidates()
	for i in entities.size():
		var entity := entities[i]
		var proj: C_ProjectileData = projectiles[i]
		var pos: C_Position = positions[i]
		var previous_position := pos.world_position
		proj.age += delta
		var step := proj.velocity * delta
		var travelled := step.length()
		pos.world_position += step
		var hit_target := _find_hit_target(entity, proj, pos.world_position, previous_position, candidate_entities)
		if hit_target != null:
			proj.has_hit = true
			if entity is BaseProjectile:
				entity.on_hit(hit_target, pos.world_position)
			cmd.remove_entity(entity)
			continue
		proj.remaining_distance = maxf(0.0, proj.remaining_distance - travelled)
		var travel_ratio := 0.0
		if proj.max_distance > 0.0:
			travel_ratio = clampf(1.0 - (proj.remaining_distance / proj.max_distance), 0.0, 1.0)
		proj.damage = maxf(0.0, proj.base_damage * (1.0 - 0.35 * travel_ratio))
		var speed := maxf(0.0, proj.base_speed * (1.0 - 0.2 * travel_ratio))
		if proj.velocity.length_squared() > 0.0:
			proj.velocity = proj.velocity.normalized() * speed
		if proj.age >= proj.lifetime or proj.remaining_distance <= 0.0:
			if entity is BaseProjectile:
				entity.on_expire()
			cmd.remove_entity(entity)


func _get_collision_candidates() -> Array[Entity]:
	if ECS.world == null:
		return []
	var query := ECS.world.query.with_all([C_Position, C_Health, C_Faction]).enabled()
	return query.execute()


func _find_hit_target(projectile_entity: Entity, projectile_data: C_ProjectileData, current_position: Vector2, previous_position: Vector2, candidate_entities: Array[Entity]) -> Entity:
	var owner_id := projectile_data.owner_entity_id
	var radius := maxf(1.0, projectile_data.collision_radius * PROJECTILE_RADIUS_SCALE)
	for candidate in candidate_entities:
		if candidate == null or candidate == projectile_entity:
			continue
		if not (candidate is BaseEntity):
			continue
		if not candidate.is_alive():
			continue
		if not owner_id.is_empty() and candidate.id == owner_id:
			continue
		if projectile_entity is BaseProjectile and not (projectile_entity as BaseProjectile).is_hostile_to(candidate):
			continue
		var candidate_position: C_Position = candidate.get_component(C_Position)
		if candidate_position == null:
			continue
		if _segment_distance_to_point_squared(previous_position, current_position, candidate_position.world_position) <= radius * radius:
			return candidate
	return null


func _segment_distance_to_point_squared(a: Vector2, b: Vector2, point: Vector2) -> float:
	var segment := b - a
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.000001:
		return point.distance_squared_to(a)
	var t := clampf((point - a).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := a + segment * t
	return point.distance_squared_to(closest)
