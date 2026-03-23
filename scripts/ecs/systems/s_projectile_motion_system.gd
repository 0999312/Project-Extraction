class_name S_ProjectileMotionSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_ProjectileData, C_Position]).iterate([C_ProjectileData, C_Position])


func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var projectiles: Array = components[0]
	var positions: Array = components[1]
	for i in entities.size():
		var entity := entities[i]
		var proj: C_ProjectileData = projectiles[i]
		var pos: C_Position = positions[i]
		proj.age += delta
		var step := proj.velocity * delta
		var travelled := step.length()
		pos.world_position += step
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
