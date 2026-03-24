class_name ProjectileMotionRuntime
extends RefCounted

const PROJECTILE_RADIUS_SCALE := 0.75

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
		projectile.global_position += step
		var hit_target := _find_hit_target(projectile, projectile.global_position, previous_position, actors)
		if hit_target != null:
			proj.has_hit = true
			projectile.on_hit(hit_target, projectile.global_position)
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

func _segment_distance_to_point_squared(a: Vector2, b: Vector2, point: Vector2) -> float:
	var segment := b - a
	var segment_length_squared := segment.length_squared()
	if segment_length_squared <= 0.000001:
		return point.distance_squared_to(a)
	var t := clampf((point - a).dot(segment) / segment_length_squared, 0.0, 1.0)
	var closest := a + segment * t
	return point.distance_squared_to(closest)
