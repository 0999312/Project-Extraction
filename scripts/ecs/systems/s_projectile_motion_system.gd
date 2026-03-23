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
		pos.world_position += proj.velocity * delta
		if proj.age >= proj.lifetime:
			cmd.remove_entity(entity)
