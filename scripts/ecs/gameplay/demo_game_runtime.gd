extends Node2D

@onready var _combat_fire_system: S_CombatFireSystem = $CombatFireSystem
@onready var _projectile_motion_system: S_ProjectileMotionSystem = $ProjectileMotionSystem
@onready var _pause_menu_controller: Node = $PauseMenuController
@onready var _player: Player = $Player
@onready var _phantom_camera_2d = $PhantomCamera2D

var _world: World
var _systems_registered: bool = false
var _pause_pressed_last_frame: bool = false
const GUIDE_ACTION_PAUSE := &"pe_pause"
const AIM_CAMERA_LERP_SPEED := 9.0


func _ready() -> void:
	_world = World.new()
	_world.name = "RuntimeWorld"
	add_child(_world)
	ECS.world = _world
	_register_systems_when_world_ready()


func _physics_process(delta: float) -> void:
	_register_systems_when_world_ready()
	_poll_pause_input()
	_update_aim_camera_offset(delta)
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


func _poll_pause_input() -> void:
	var action: GUIDEAction = GuideInputRuntime.get_action(GUIDE_ACTION_PAUSE)
	if action == null:
		return
	var is_triggered := action.is_triggered()
	if is_triggered and not _pause_pressed_last_frame:
		if _pause_menu_controller != null:
			_pause_menu_controller.pause()
	_pause_pressed_last_frame = is_triggered


func _update_aim_camera_offset(delta: float) -> void:
	if _player == null or _phantom_camera_2d == null:
		return
	var ecs_entity := _player.get_ecs_entity()
	if ecs_entity == null:
		return
	var combat: C_CombatState = ecs_entity.get_component(C_CombatState)
	if combat == null:
		return
	var target_offset := Vector2.ZERO
	if combat.is_aiming:
		var to_mouse := _player.get_global_mouse_position() - _player.global_position
		var aim_dir := to_mouse.normalized() if to_mouse.length_squared() > 0.0001 else Vector2.RIGHT
		target_offset = aim_dir * combat.ads_distance
	var current_offset: Vector2 = _phantom_camera_2d.follow_offset
	_phantom_camera_2d.follow_offset = current_offset.lerp(target_offset, clampf(delta * AIM_CAMERA_LERP_SPEED, 0.0, 1.0))
