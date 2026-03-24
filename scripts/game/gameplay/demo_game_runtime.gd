extends Node2D

@onready var _player_spawn: Marker2D = $PlayerSpawn
@onready var _human_enemy_spawn: Marker2D = $HumanEnemySpawn
@onready var _non_human_enemy_spawn: Marker2D = $NonHumanEnemySpawn
@onready var _pause_menu_controller: Node = $PauseMenuController
@onready var _phantom_camera_2d = $PhantomCamera2D

var _player: Player = null
var _human_enemy: HumanEnemy = null
var _non_human_enemy: NonHumanEnemy = null
var _crosshair: CrosshairNode = null
var _camera_following_crosshair: bool = false
var _default_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE

var _combat_fire_system := CombatFireRuntime.new()
var _projectile_motion_system := ProjectileMotionRuntime.new()
var _projectiles: Node2D = null
var _pause_pressed_last_frame: bool = false

const GUIDE_ACTION_PAUSE := &"pe_pause"
const GUIDE_ACTION_AIM_AXIS := &"pe_aim_axis"
const AIM_AXIS_EPSILON := 0.0001

func _ready() -> void:
	EntityCatalog.ensure_registry()
	ProjectileCatalog.ensure_registry()
	_spawn_runtime_entities()
	_setup_crosshair()
	_projectiles = get_node_or_null("Projectiles")
	if _projectiles == null:
		_projectiles = Node2D.new()
		_projectiles.name = "Projectiles"
		add_child(_projectiles)
	_combat_fire_system.setup()
	process_physics_priority = 100
	_assign_enemy_targets()
	_default_mouse_mode = Input.mouse_mode
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	print("[DEBUG][DemoGame] _ready | actors=%d" % _get_runtime_actors().size())

func _exit_tree() -> void:
	Input.set_mouse_mode(_default_mouse_mode)

func _spawn_runtime_entities() -> void:
	_player = _spawn_registered_entity(EntityCatalog.PLAYER, _player_spawn.global_position, "Player") as Player
	_human_enemy = _spawn_registered_entity(EntityCatalog.HUMAN_ENEMY, _human_enemy_spawn.global_position, "HumanEnemy") as HumanEnemy
	_non_human_enemy = _spawn_registered_entity(EntityCatalog.NON_HUMAN_ENEMY, _non_human_enemy_spawn.global_position, "NonHumanEnemy") as NonHumanEnemy
	if _phantom_camera_2d != null and _player != null:
		_phantom_camera_2d.follow_target = _player


func _spawn_registered_entity(entity_id: String, spawn_position: Vector2, node_name: String) -> Node:
	var entity := EntityCatalog.instantiate_entity(entity_id, node_name)
	if entity == null:
		return null
	add_child(entity)
	if entity is Node2D:
		entity.global_position = spawn_position
	return entity

func _physics_process(delta: float) -> void:
	_assign_enemy_targets()
	_poll_pause_input()
	_update_crosshair_and_camera_target()
	_update_player_aim_from_crosshair()
	_combat_fire_system.process(_get_runtime_actors(), _projectiles, delta)
	_projectile_motion_system.process(_projectiles, _get_runtime_actors(), delta)

func _get_runtime_actors() -> Array:
	var actors: Array = []
	for node in get_tree().get_nodes_in_group("actors"):
		if node is BiologicalActor:
			actors.append(node)
	return actors

func _assign_enemy_targets() -> void:
	if _human_enemy != null:
		_human_enemy.set_target_actor(_player)
	if _non_human_enemy != null:
		_non_human_enemy.set_target_actor(_player)

func _poll_pause_input() -> void:
	var is_triggered := GuideInputRuntime.is_action_triggered(GUIDE_ACTION_PAUSE)
	if is_triggered and not _pause_pressed_last_frame and _pause_menu_controller != null:
		_pause_menu_controller.pause()
	_pause_pressed_last_frame = is_triggered

func _setup_crosshair() -> void:
	_crosshair = CrosshairNode.new()
	_crosshair.name = "Crosshair"
	add_child(_crosshair)

func _update_crosshair_and_camera_target() -> void:
	if _crosshair == null:
		return
	if _player == null or _phantom_camera_2d == null:
		return
	var combat: CombatState = _player.get_combat_state()
	if combat == null:
		return
	var relaxed := _is_relaxed_state()
	if relaxed:
		_crosshair.set_mode(CrosshairNode.Mode.RELAXED)
	else:
		_crosshair.set_mode(CrosshairNode.Mode.ADS if combat.is_aiming else CrosshairNode.Mode.HIP_FIRE)
	if _is_using_aim_axis():
		var aim_axis := GuideInputRuntime.get_action_axis_2d(GUIDE_ACTION_AIM_AXIS).normalized()
		var stick_distance := combat.ads_distance if combat.is_aiming else maxf(32.0, combat.ads_distance * 0.6)
		_crosshair.global_position = _player.global_position + aim_axis * stick_distance
	else:
		_crosshair.update_position(_player.global_position, combat.is_aiming, combat.ads_distance)
	var should_follow_crosshair := combat.is_aiming and not relaxed
	if should_follow_crosshair != _camera_following_crosshair:
		_camera_following_crosshair = should_follow_crosshair
		_phantom_camera_2d.follow_target = _crosshair if should_follow_crosshair else _player
	var transition_sec := maxf(0.01, combat.aim_transition_sec)
	_phantom_camera_2d.follow_damping = true
	_phantom_camera_2d.follow_damping_value = Vector2(transition_sec, transition_sec)
	_phantom_camera_2d.follow_offset = Vector2.ZERO

func _update_player_aim_from_crosshair() -> void:
	if _player == null or _crosshair == null:
		return
	var aim: AimState = _player.get_aim_state()
	if aim == null:
		return
	if _is_using_aim_axis():
		return
	aim.aim_direction = _crosshair.get_effective_aim_direction(_player.global_position, aim.aim_direction)

func _is_relaxed_state() -> bool:
	return get_tree().paused

func _is_using_aim_axis() -> bool:
	return GuideInputRuntime.get_action_axis_2d(GUIDE_ACTION_AIM_AXIS).length_squared() > AIM_AXIS_EPSILON
