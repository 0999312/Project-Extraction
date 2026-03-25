class_name ProjectileMotionRuntime
extends RefCounted

const PROJECTILE_RADIUS_SCALE := 0.75
const PHYSICS_EPSILON := 0.001

func process(projectile_parent: Node, actors: Array, delta: float) -> void:
	if projectile_parent == null:
		return
	for projectile_variant in projectile_parent.get_children():
		if not (projectile_variant is Projectile):
			continue
		var projectile: Projectile = projectile_variant
		var proj: ProjectileData = projectile.projectile_data
		if proj == null:
			projectile.queue_free()
			continue
		var previous_position := projectile.global_position
		proj.age += delta
		var step := proj.velocity * delta
		var travelled := step.length()
		var current_position := previous_position + step
		var collision_info := _find_collision(projectile, previous_position, current_position, actors, projectile_parent)
		projectile.global_position = collision_info.position
		var hit_target = collision_info.actor
		if hit_target != null:
			proj.has_hit = true
			projectile.on_hit(hit_target, projectile.global_position)
			continue
		if collision_info.blocked:
			projectile.on_expire()
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
			projectile.on_expire()

func _find_collision(projectile: Projectile, previous_position: Vector2, current_position: Vector2, actors: Array, projectile_parent: Node) -> Dictionary:
	var hit_target := _find_hit_target(projectile, current_position, previous_position, actors)
	if hit_target != null:
		return {
			"actor": hit_target,
			"blocked": false,
			"position": current_position,
		}
	var blocked := _is_blocked_by_air_collision(projectile, previous_position, current_position, projectile_parent)
	return {
		"actor": null,
		"blocked": blocked,
		"position": current_position,
	}

func _find_hit_target(projectile: Projectile, current_position: Vector2, previous_position: Vector2, actors: Array) -> BiologicalActor:
	var owner_id := projectile.owner_actor_id
	var radius := maxf(1.0, projectile.projectile_data.collision_radius * PROJECTILE_RADIUS_SCALE)
	for actor_variant in actors:
		if not (actor_variant is BiologicalActor):
			continue
		var actor: BiologicalActor = actor_variant
		if not actor.is_alive():
			continue
		if owner_id == actor.get_actor_id():
			continue
		if not projectile.is_hostile_to(actor):
			continue
		if _segment_distance_to_point_squared(previous_position, current_position, actor.global_position) <= radius * radius:
			return actor
	return null

func _is_blocked_by_air_collision(projectile: Projectile, previous_position: Vector2, current_position: Vector2, projectile_parent: Node) -> bool:
	if projectile_parent == null:
		return false
	var world : World2D = projectile_parent.get_world_2d()
	if world == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(previous_position, current_position)
	query.collision_mask = ProjectileData.COLLISION_LAYER_AIR
	#query.exclude = [projectile.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var space_state := world.direct_space_state
	if space_state == null:
		return false
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider = hit.get("collider")
	if collider is BiologicalActor:
		return false
	var hit_position: Variant = hit.get("position")
	if hit_position is Vector2:
		if (hit_position as Vector2).distance_squared_to(previous_position) <= PHYSICS_EPSILON * PHYSICS_EPSILON:
			return false
	return true

func _segment_distance_to_point_squared(a: Vector2, b: Vector2, point: Vector2) -> float:
	var segment := b - a
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.000001:
		return point.distance_squared_to(a)
	var t := clampf((point - a).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := a + segment * t
	return point.distance_squared_to(closest)
