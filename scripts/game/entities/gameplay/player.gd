class_name Player
extends HumanActor

const BASE_SPEED: float = 200.0
const BASE_SPRINT_SPEED: float = 320.0
const STAMINA_SPRINT_COST_PER_SEC: float = 15.0
const MOVE_INPUT_EPSILON: float = 0.01
const GUIDE_ACTION_MOVE := &"pe_move"
const GUIDE_ACTION_AIM_AXIS := &"pe_aim_axis"
const GUIDE_ACTION_FIRE := &"pe_fire"
const GUIDE_ACTION_AIM_HOLD := &"pe_aim_hold"
const GUIDE_ACTION_RELOAD := &"pe_reload"
const GUIDE_ACTION_FIRE_MODE_TOGGLE := &"pe_fire_mode_toggle"
const GUIDE_ACTION_SPRINT := &"pe_sprint"

var move_input: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var is_sprinting: bool = false

var _using_gamepad_aim: bool = false
var _reload_pressed_last_frame: bool = false
var _fire_mode_pressed_last_frame: bool = false

func _ready() -> void:
	_setup_runtime_state()
	super._ready()
	add_to_group("player")
	GuideInputRuntime.ensure_initialized()
	GUIDE.enable_mapping_context(GuideInputRuntime.get_context())
	print("[DEBUG][Player] _ready | group=player GUIDE_context_enabled")

func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	_poll_guide_input()
	_handle_sprint_stamina(delta)
	_sync_input_to_runtime()
	apply_velocity_movement()
	sync_runtime_position()

func _setup_runtime_state() -> void:
	body_color = Color("ffff66")
	health = HealthState.new(100.0)
	stamina_state = StaminaState.new(100.0, 10.0)
	status_effects = StatusEffectsState.new()
	position_state = PositionState.new(global_position)
	velocity_state = VelocityState.new(BASE_SPEED)
	combat_state = CombatState.new()
	inventory_ref = InventoryState.new()
	faction_state = FactionState.new(FactionState.FactionType.PLAYER)
	aim_state = AimState.new()
	combat_state.equipped_weapon_id = "game:item/weapon/pistol"
	combat_state.projectile_definition_id = ProjectileCatalog.BULLET
	combat_state.ammo_max = 15
	combat_state.ammo_current = 15

func _get_aim_direction() -> Vector2:
	if _using_gamepad_aim and aim_direction.length_squared() > AIM_EPSILON:
		return aim_direction.normalized()
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length_squared() > AIM_EPSILON:
		return to_mouse.normalized()
	return aim_direction if aim_direction != Vector2.ZERO else Vector2.RIGHT

func _handle_sprint_stamina(delta: float) -> void:
	if not is_sprinting or move_input.length_squared() < MOVE_INPUT_EPSILON:
		if stamina_state != null:
			stamina_state.current_stamina = minf(stamina_state.max_stamina, stamina_state.current_stamina + stamina_state.regen_rate * delta)
			stamina_state.is_exhausted = stamina_state.current_stamina < stamina_state.exhaustion_threshold
		return
	if stamina_state == null:
		return
	var cost := STAMINA_SPRINT_COST_PER_SEC * delta
	if stamina_state.current_stamina < cost:
		is_sprinting = false
		return
	stamina_state.current_stamina = maxf(0.0, stamina_state.current_stamina - cost)
	stamina_state.is_exhausted = stamina_state.current_stamina < stamina_state.exhaustion_threshold

func _sync_input_to_runtime() -> void:
	if velocity_state != null:
		velocity_state.velocity = move_input.normalized() * _get_current_speed()
	if combat_state != null:
		var prev_aiming := combat_state.is_aiming
		var prev_fire := combat_state.wants_fire
		combat_state.is_aiming = GuideInputRuntime.is_action_triggered(GUIDE_ACTION_AIM_HOLD)
		combat_state.wants_fire = GuideInputRuntime.is_action_triggered(GUIDE_ACTION_FIRE)
		var reload_pressed := GuideInputRuntime.is_action_triggered(GUIDE_ACTION_RELOAD)
		combat_state.wants_reload = reload_pressed and not _reload_pressed_last_frame
		_reload_pressed_last_frame = reload_pressed
		var fire_mode_pressed := GuideInputRuntime.is_action_triggered(GUIDE_ACTION_FIRE_MODE_TOGGLE)
		combat_state.wants_fire_mode_toggle = fire_mode_pressed and not _fire_mode_pressed_last_frame
		_fire_mode_pressed_last_frame = fire_mode_pressed
		if combat_state.is_aiming != prev_aiming:
			print("[DEBUG][Player] AIM %s | dir=(%.2f,%.2f)" % ["ON" if combat_state.is_aiming else "OFF", aim_direction.x, aim_direction.y])
		if combat_state.wants_fire and not prev_fire:
			print("[DEBUG][Player] FIRE pressed | aiming=%s ammo=%d/%d mode=%s" % [combat_state.is_aiming, combat_state.ammo_current, combat_state.ammo_max, CombatState.FireMode.keys()[combat_state.fire_mode]])
		if combat_state.wants_reload:
			print("[DEBUG][Player] RELOAD requested | ammo=%d/%d" % [combat_state.ammo_current, combat_state.ammo_max])
		if combat_state.wants_fire_mode_toggle:
			print("[DEBUG][Player] FIRE_MODE_TOGGLE requested")
	if aim_state != null:
		aim_state.aim_direction = _get_aim_direction()

func _get_current_speed() -> float:
	var selected_speed := BASE_SPRINT_SPEED if is_sprinting else BASE_SPEED
	var mult := 1.0
	if inventory_ref != null and inventory_ref.max_weight > 0.0:
		var enc_ratio := inventory_ref.current_weight / inventory_ref.max_weight
		mult *= clampf(1.0 - enc_ratio * 0.5, 0.3, 1.0)
	if status_effects != null and status_effects.fracture:
		mult *= status_effects.fracture_move_speed_mult
	return selected_speed * mult

func _poll_guide_input() -> void:
	var prev_move := move_input
	var prev_sprint := is_sprinting
	move_input = GuideInputRuntime.get_action_axis_2d(GUIDE_ACTION_MOVE).limit_length(1.0)
	is_sprinting = GuideInputRuntime.is_action_triggered(GUIDE_ACTION_SPRINT) and (stamina_state == null or not stamina_state.is_exhausted)
	var stick_aim := GuideInputRuntime.get_action_axis_2d(GUIDE_ACTION_AIM_AXIS)
	_using_gamepad_aim = stick_aim.length_squared() > AIM_EPSILON
	if _using_gamepad_aim:
		aim_direction = stick_aim.normalized()
	var started_move := prev_move.length_squared() < MOVE_INPUT_EPSILON and move_input.length_squared() >= MOVE_INPUT_EPSILON
	var stopped_move := prev_move.length_squared() >= MOVE_INPUT_EPSILON and move_input.length_squared() < MOVE_INPUT_EPSILON
	if started_move:
		print("[DEBUG][Player] MOVE started | dir=(%.2f,%.2f) speed=%.0f" % [move_input.x, move_input.y, _get_current_speed()])
	elif stopped_move:
		print("[DEBUG][Player] MOVE stopped")
	if is_sprinting != prev_sprint:
		print("[DEBUG][Player] SPRINT %s" % ("ON" if is_sprinting else "OFF"))
