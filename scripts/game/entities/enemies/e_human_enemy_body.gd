class_name HumanEnemyBody
extends HumanBase

var _target_actor: Player = null

func _ready() -> void:
	_setup_runtime_state()
	super._ready()
	add_to_group("enemies")
	add_to_group("human_enemies")

func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	_update_simple_ai(delta)
	apply_velocity_movement()
	sync_runtime_position()

func _setup_runtime_state() -> void:
	health = C_Health.new(80.0)
	stamina_state = C_Stamina.new(80.0, 5.0)
	status_effects = C_StatusEffects.new()
	position_state = C_Position.new(global_position)
	velocity_state = C_Velocity.new(160.0, 600.0, 500.0)
	combat_state = C_CombatState.new()
	inventory_ref = C_InventoryRef.new()
	faction_state = C_Faction.new(C_Faction.FactionType.HUMAN_ENEMY)
	ai_state = C_AIState.new(280.0, 200.0)
	aim_state = C_AimState.new()
	combat_state.equipped_weapon_id = "game:item/weapon/pistol"
	combat_state.ammo_max = 12
	combat_state.ammo_current = 12

func set_target_actor(actor: Player) -> void:
	_target_actor = actor

func _get_aim_direction() -> Vector2:
	if aim_state != null and aim_state.aim_direction.length_squared() > AIM_EPSILON:
		return aim_state.aim_direction
	return Vector2.RIGHT

func _update_simple_ai(delta: float) -> void:
	var player := _resolve_target_actor()
	combat_state.wants_reload = false
	combat_state.wants_fire_mode_toggle = false
	if player == null or not player.is_alive():
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.wants_fire = false
		combat_state.is_aiming = false
		if ai_state != null:
			ai_state.behavior = C_AIState.AIBehavior.IDLE
		return
	var to_target := player.global_position - global_position
	if to_target.length_squared() > AIM_EPSILON:
		aim_state.aim_direction = to_target.normalized()
	if ai_state != null:
		ai_state.last_known_target_position = player.global_position
		ai_state.state_timer += delta
	var distance := to_target.length()
	if ai_state != null and distance <= ai_state.attack_radius:
		ai_state.behavior = C_AIState.AIBehavior.ATTACK
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.is_aiming = true
		combat_state.wants_fire = true
	elif ai_state != null and distance <= ai_state.detection_radius:
		ai_state.behavior = C_AIState.AIBehavior.CHASE
		if velocity_state != null:
			velocity_state.velocity = to_target.normalized() * minf(velocity_state.max_speed, 70.0)
		combat_state.is_aiming = true
		combat_state.wants_fire = false
	else:
		if ai_state != null:
			ai_state.behavior = C_AIState.AIBehavior.IDLE
		if velocity_state != null:
			velocity_state.velocity = Vector2.ZERO
		combat_state.is_aiming = false
		combat_state.wants_fire = false

func _resolve_target_actor() -> Player:
	var found := resolve_first_group_node(_target_actor, &"player")
	if found is Player:
		_target_actor = found
	else:
		_target_actor = null
	return _target_actor
