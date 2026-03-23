extends Node2D

@onready var _combat_fire_system: S_CombatFireSystem = $CombatFireSystem
@onready var _projectile_motion_system: S_ProjectileMotionSystem = $ProjectileMotionSystem

var _world: World
var _systems_registered: bool = false


func _ready() -> void:
	_world = World.new()
	_world.name = "RuntimeWorld"
	add_child(_world)
	ECS.world = _world
	_register_systems_when_world_ready()


func _physics_process(delta: float) -> void:
	_register_systems_when_world_ready()
	if ECS.world != null:
		ECS.process(delta)


func _register_systems_when_world_ready() -> void:
	if _systems_registered:
		return
	if ECS.world == null:
		return
	if ECS.world.systems.has(_combat_fire_system) and ECS.world.systems.has(_projectile_motion_system):
		_systems_registered = true
		return
	if _combat_fire_system.get_parent() != null:
		_combat_fire_system.get_parent().remove_child(_combat_fire_system)
	if _projectile_motion_system.get_parent() != null:
		_projectile_motion_system.get_parent().remove_child(_projectile_motion_system)
	ECS.world.add_system(_combat_fire_system)
	ECS.world.add_system(_projectile_motion_system)
	_systems_registered = true
