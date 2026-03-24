## BiologicalBodyBase
##
## Shared [CharacterBody2D] bridge base for biological actors (player and enemies).
## Handles safe registration of a child ECS [Entity] to the active GECS [World],
## including delayed registration when [member ECS.world] is assigned later.
class_name BiologicalBodyBase
extends CharacterBody2D


## Registers [param ecs_entity] into the current world, or defers registration
## until [signal ECS.world_changed] if no world exists yet.
func register_ecs_entity(ecs_entity: Entity) -> void:
	if ecs_entity == null:
		return
	if ECS.world != null:
		_register_entity_to_world(ECS.world, ecs_entity)
		return
	if not ECS.world_changed.is_connected(_on_ecs_world_changed):
		ECS.world_changed.connect(_on_ecs_world_changed.bind(ecs_entity), CONNECT_ONE_SHOT)


func _on_ecs_world_changed(world: World, ecs_entity: Entity) -> void:
	_register_entity_to_world(world, ecs_entity)


func _register_entity_to_world(world: World, ecs_entity: Entity) -> void:
	if world == null or ecs_entity == null:
		return
	if world.entities.has(ecs_entity):
		return
	world.add_entity(ecs_entity)
