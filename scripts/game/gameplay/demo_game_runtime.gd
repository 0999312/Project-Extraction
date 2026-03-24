extends Node2D

@onready var _player_spawn: Marker2D = $PlayerSpawn
@onready var _human_enemy_spawn: Marker2D = $HumanEnemySpawn
@onready var _non_human_enemy_spawn: Marker2D = $NonHumanEnemySpawn
@onready var _pause_menu_controller: Node = $PauseMenuController
@onready var _phantom_camera_2d = $PhantomCamera2D

var _player: Player = null
var _human_enemy: HumanEnemy = null
var _non_human_enemy: NonHumanEnemy = null

var _combat_fire_system := CombatFireRuntime.new()
var _projectile_motion_system := ProjectileMotionRuntime.new()
var _projectiles: Node2D = null
var _pause_pressed_last_frame: bool = false

const GUIDE_ACTION_PAUSE := &"pe_pause"
const AIM_CAMERA_LERP_SPEED := 9.0

func _ready() -> void:
	EntityCatalog.ensure_registry()
	ProjectileCatalog.ensure_registry()
	_spawn_runtime_entities()
	_projectiles = get_node_or_null("Projectiles")
	if _projectiles == null:
		_projectiles = Node2D.new()
		_projectiles.name = "Projectiles"
		add_child(_projectiles)
	_combat_fire_system.setup()
	process_physics_priority = 100
	_assign_enemy_targets()
	print("[DEBUG][DemoGame] _ready | actors=%d" % _get_runtime_actors().size())


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
	_combat_fire_system.process(_get_runtime_actors(), _projectiles, delta)
	_projectile_motion_system.process(_projectiles, _get_runtime_actors(), delta)
	_update_aim_camera_offset(delta)

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

func _update_aim_camera_offset(delta: float) -> void:
	if _player == null or _phantom_camera_2d == null:
		return
	var combat: CombatState = _player.get_combat_state()
	if combat == null:
		return
	var target_offset := Vector2.ZERO
	if combat.is_aiming:
		var to_mouse := _player.get_global_mouse_position() - _player.global_position
		var aim_dir := to_mouse.normalized() if to_mouse.length_squared() > 0.0001 else Vector2.RIGHT
		target_offset = aim_dir * combat.ads_distance
	var current_offset: Vector2 = _phantom_camera_2d.follow_offset
	_phantom_camera_2d.follow_offset = current_offset.lerp(target_offset, clampf(delta * AIM_CAMERA_LERP_SPEED, 0.0, 1.0))
