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
var _camera_aim_target: Node2D = null
var _ads_vignette: AdsVignetteOverlay = null
var _camera_following_crosshair: bool = false
var _default_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE
var _last_camera_transition_sec: float = -1.0

var _combat_fire_system := CombatFireRuntime.new()
var _projectile_motion_system := ProjectileMotionRuntime.new()
var _projectiles: Node2D = null
var _pause_pressed_last_frame: bool = false
var _inventory_menu: InventoryMenu = null
var _inventory_pressed_last_frame: bool = false
var _player_hud: PlayerHUD = null

const GUIDE_ACTION_PAUSE := &"pe_pause"
const GUIDE_ACTION_INVENTORY := &"pe_inventory"
const GUIDE_ACTION_AIM_AXIS_OPTIONAL := &"pe_aim_axis"
const AIM_AXIS_EPSILON := 0.0001
const AIM_DISTANCE_EPSILON := 0.0001
const HIP_FIRE_AXIS_DISTANCE_RATIO := 0.6
const MIN_HIP_FIRE_AXIS_DISTANCE := 32.0
const MIN_AIM_TRANSITION_SEC := 0.01

func _ready() -> void:
	ItemCatalog.ensure_registry()
	WeaponCatalog.ensure_registry()
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
	_setup_inventory_menu()
	_setup_player_hud()
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
	_poll_inventory_input()
	if _inventory_menu == null or not _inventory_menu.is_open():
		_update_crosshair_and_camera_target()
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
	_camera_aim_target = Node2D.new()
	_camera_aim_target.name = "CameraAimTarget"
	_camera_aim_target.top_level = true
	add_child(_camera_aim_target)
	_ads_vignette = AdsVignetteOverlay.new()
	_ads_vignette.name = "AdsVignetteOverlay"
	add_child(_ads_vignette)

func _update_crosshair_and_camera_target() -> void:
	if _crosshair == null:
		return
	if _player == null or _phantom_camera_2d == null:
		return
	var combat: CombatState = _player.get_combat_state()
	if combat == null:
		return
	var aim_axis := GuideInputRuntime.get_action_axis_2d(GUIDE_ACTION_AIM_AXIS_OPTIONAL)
	var using_aim_axis := aim_axis.length_squared() > AIM_AXIS_EPSILON
	var relaxed := _is_relaxed_state()
	if relaxed:
		_crosshair.set_mode(CrosshairNode.Mode.RELAXED)
	else:
		_crosshair.set_mode(CrosshairNode.Mode.ADS if combat.is_aiming else CrosshairNode.Mode.HIP_FIRE)
	if using_aim_axis:
		var normalized_aim_axis := aim_axis.normalized()
		var calculated_hip_fire_distance := maxf(MIN_HIP_FIRE_AXIS_DISTANCE, combat.ads_distance * HIP_FIRE_AXIS_DISTANCE_RATIO)
		var effective_crosshair_distance := combat.ads_distance if combat.is_aiming else calculated_hip_fire_distance
		_crosshair.global_position = _player.global_position + normalized_aim_axis * effective_crosshair_distance
	else:
		_crosshair.update_position(_player.global_position, combat.is_aiming, combat.ads_distance)
	if _camera_aim_target != null:
		var to_crosshair := _crosshair.global_position - _player.global_position
		var max_distance := maxf(0.0, combat.ads_distance)
		if max_distance > 0.0 and to_crosshair.length_squared() > AIM_DISTANCE_EPSILON:
			_camera_aim_target.global_position = _player.global_position + to_crosshair.limit_length(max_distance)
		else:
			_camera_aim_target.global_position = _crosshair.global_position
	var should_follow_crosshair := combat.is_aiming and not relaxed
	if should_follow_crosshair != _camera_following_crosshair:
		_camera_following_crosshair = should_follow_crosshair
		if _camera_aim_target != null:
			_phantom_camera_2d.follow_target = _camera_aim_target if should_follow_crosshair else _player
		else:
			_phantom_camera_2d.follow_target = _crosshair as Node2D if should_follow_crosshair else _player
	var transition_sec := maxf(MIN_AIM_TRANSITION_SEC, combat.aim_transition_sec)
	if _last_camera_transition_sec != transition_sec:
		_last_camera_transition_sec = transition_sec
		_phantom_camera_2d.follow_damping = true
		_phantom_camera_2d.follow_damping_value = Vector2(transition_sec, transition_sec)
	_phantom_camera_2d.follow_offset = Vector2.ZERO
	_update_player_aim_from_crosshair(using_aim_axis)
	_update_ads_vignette(combat.is_aiming and not relaxed)

func _update_player_aim_from_crosshair(using_aim_axis: bool) -> void:
	if _player == null or _crosshair == null:
		return
	var aim: AimState = _player.get_aim_state()
	if aim == null:
		return
	if using_aim_axis:
		return
	aim.aim_direction = _crosshair.get_effective_aim_direction(_player.global_position, aim.aim_direction)

func _update_ads_vignette(active: bool) -> void:
	if _ads_vignette == null:
		return
	_ads_vignette.set_active(active)
	if active and _crosshair != null:
		var viewport := get_viewport()
		if viewport != null:
			var screen_pos := viewport.get_canvas_transform() * _crosshair.global_position
			_ads_vignette.update_center(screen_pos)

func _is_relaxed_state() -> bool:
	if _inventory_menu != null and _inventory_menu.is_open():
		return true
	return get_tree().paused

func _setup_inventory_menu() -> void:
	_inventory_menu = InventoryMenu.new()
	_inventory_menu.name = "InventoryMenu"
	add_child(_inventory_menu)
	if _player != null and _player.inventory_ref != null and _player.inventory_ref.inventory != null:
		_inventory_menu.bind_inventory(_player.inventory_ref.inventory)
		# Set hotbar slot 0 to the equipped weapon
		if _player.combat_state != null and not _player.combat_state.equipped_weapon_id.is_empty():
			_player.inventory_ref.inventory.set_hotbar_slot(0, _player.combat_state.equipped_weapon_id)
	_inventory_menu.held_item_changed.connect(_on_held_item_changed)

func _poll_inventory_input() -> void:
	var is_triggered := GuideInputRuntime.is_action_triggered(GUIDE_ACTION_INVENTORY)
	if is_triggered and not _inventory_pressed_last_frame:
		if _inventory_menu != null:
			_inventory_menu.toggle()
	_inventory_pressed_last_frame = is_triggered

func _on_held_item_changed(item_id: String) -> void:
	if _player == null or _player.combat_state == null:
		return
	if item_id.is_empty():
		return
	_player.combat_state.equipped_weapon_id = item_id
	WeaponCatalog.apply_to_combat_state(_player.combat_state)
	print("[DEBUG][DemoGame] Held item changed to: %s" % item_id)

func _setup_player_hud() -> void:
	var hud_scene := load("res://scenes/game_scene/player_hud.tscn")
	if hud_scene == null:
		push_warning("[DemoGame] Failed to load player_hud.tscn")
		return
	_player_hud = hud_scene.instantiate() as PlayerHUD
	if _player_hud == null:
		return
	add_child(_player_hud)
	if _player != null and _player.inventory_ref != null and _player.inventory_ref.inventory != null:
		_player_hud.bind_inventory(_player.inventory_ref.inventory)
	_player_hud.hotbar_selection_changed.connect(_on_held_item_changed)
