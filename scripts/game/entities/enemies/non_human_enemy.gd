class_name NonHumanEnemy
extends BiologicalActor

enum EnemyVariant {
	SWARMER,
	CHARGER,
	DRONE,
	BLOB,
}

const AIM_EPSILON: float = 0.0001

@export var variant: EnemyVariant = EnemyVariant.SWARMER

var _target_actor: Player = null

func _ready() -> void:
	_setup_runtime_state()
	super._ready()
	add_to_group("enemies")
	add_to_group("non_human_enemies")

func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	_update_simple_ai(delta)
	_update_body_rotation()
	apply_velocity_movement()
	sync_runtime_position()

func _setup_runtime_state() -> void:
	match variant:
		EnemyVariant.SWARMER:
			health = HealthState.new(25.0)
			velocity_state = VelocityState.new(280.0, 1200.0, 800.0)
			ai_state = AIState.new(350.0, 60.0)
		EnemyVariant.CHARGER:
			health = HealthState.new(200.0)
			velocity_state = VelocityState.new(180.0, 400.0, 300.0)
			ai_state = AIState.new(250.0, 80.0)
		EnemyVariant.DRONE:
			health = HealthState.new(50.0)
			velocity_state = VelocityState.new(240.0, 700.0, 500.0)
			ai_state = AIState.new(450.0, 300.0)
		EnemyVariant.BLOB:
			health = HealthState.new(150.0)
			velocity_state = VelocityState.new(80.0, 200.0, 150.0)
			ai_state = AIState.new(200.0, 100.0)
	status_effects = StatusEffectsState.new()
	position_state = PositionState.new(global_position)
	combat_state = CombatState.new()
	faction_state = FactionState.new(FactionState.FactionType.NON_HUMAN_ENEMY)
	aim_state = AimState.new()
	combat_state.equipped_weapon_id = ItemCatalog.ITEM_WEAPON_CREATURE
	WeaponCatalog.apply_to_combat_state(combat_state)

func set_target_actor(actor: Player) -> void:
	_target_actor = actor

func _update_simple_ai(delta: float) -> void:
	var player := _resolve_target_actor()
	combat_state.wants_reload = false
	combat_state.wants_fire_mode_toggle = false
	if player == null or not player.is_alive():
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.wants_fire = false
		combat_state.is_aiming = false
		ai_state.behavior = AIState.AIBehavior.IDLE
		return
	var to_target := player.global_position - global_position
	if to_target.length_squared() > AIM_EPSILON:
		aim_state.aim_direction = to_target.normalized()
	ai_state.last_known_target_position = player.global_position
	ai_state.state_timer += delta
	var distance := to_target.length()
	if distance <= ai_state.attack_radius:
		ai_state.behavior = AIState.AIBehavior.ATTACK
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.is_aiming = true
		combat_state.wants_fire = variant == EnemyVariant.DRONE
	elif distance <= ai_state.detection_radius:
		ai_state.behavior = AIState.AIBehavior.CHASE
		if velocity_state != null:
			velocity_state.velocity = to_target.normalized() * velocity_state.max_speed
		combat_state.is_aiming = variant == EnemyVariant.DRONE
		combat_state.wants_fire = false
	else:
		ai_state.behavior = AIState.AIBehavior.IDLE
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.is_aiming = false
		combat_state.wants_fire = false

func _update_body_rotation() -> void:
	if aim_state != null and aim_state.aim_direction.length_squared() > AIM_EPSILON:
		rotation = aim_state.aim_direction.angle()

func _resolve_target_actor() -> Player:
	var found := resolve_first_group_node(_target_actor, &"player")
	if found is Player:
		_target_actor = found
	else:
		_target_actor = null
	return _target_actor
