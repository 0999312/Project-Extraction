class_name BiologicalBodyBase
extends CharacterBody2D

var actor_id: String = ""
var health: C_Health = null
var stamina_state: C_Stamina = null
var status_effects: C_StatusEffects = null
var position_state: C_Position = null
var velocity_state: C_Velocity = null
var combat_state: C_CombatState = null
var inventory_ref: C_InventoryRef = null
var faction_state: C_Faction = null
var aim_state: C_AimState = null
var ai_state: C_AIState = null

func _ready() -> void:
	actor_id = "%s_%s" % [name.to_lower(), str(get_instance_id())]
	add_to_group("actors")
	if position_state == null:
		position_state = C_Position.new(global_position)
	sync_runtime_position()

func sync_runtime_position() -> void:
	if position_state != null:
		position_state.world_position = global_position
		if aim_state != null:
			position_state.facing_angle = aim_state.aim_direction.angle()


func apply_velocity_movement() -> void:
	if velocity_state != null:
		velocity = velocity_state.velocity
	move_and_slide()


func resolve_first_group_node(current_target: Node, group_name: StringName) -> Node:
	if is_instance_valid(current_target):
		return current_target
	var found := get_tree().get_first_node_in_group(group_name)
	return found if found is Node else null

func get_actor_id() -> String:
	return actor_id

func get_health() -> C_Health:
	return health

func get_stamina_state() -> C_Stamina:
	return stamina_state

func get_status_effects() -> C_StatusEffects:
	return status_effects

func get_position_state() -> C_Position:
	return position_state

func get_velocity_state() -> C_Velocity:
	return velocity_state

func get_combat_state() -> C_CombatState:
	return combat_state

func get_inventory_ref() -> C_InventoryRef:
	return inventory_ref

func get_faction_state() -> C_Faction:
	return faction_state

func get_aim_state() -> C_AimState:
	return aim_state

func get_ai_state() -> C_AIState:
	return ai_state

func is_alive() -> bool:
	return health != null and not health.is_dead

func apply_damage(amount: float, source_id: String = "") -> void:
	if health == null or health.is_dead:
		return
	health.current_hp = maxf(0.0, health.current_hp - amount)
	if health.current_hp <= 0.0:
		health.is_dead = true
		on_death(source_id)

func on_death(_killer_id: String = "") -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)
	if has_node("CollisionShape2D"):
		var shape := get_node("CollisionShape2D")
		if shape is CollisionShape2D:
			shape.disabled = true
	modulate = Color(1.0, 1.0, 1.0, 0.55)

func is_hostile_to(other: BiologicalBodyBase) -> bool:
	if other == null or faction_state == null or other.faction_state == null:
		return false
	match faction_state.faction:
		C_Faction.FactionType.PLAYER:
			return other.faction_state.faction in [C_Faction.FactionType.HUMAN_ENEMY, C_Faction.FactionType.NON_HUMAN_ENEMY]
		C_Faction.FactionType.HUMAN_ENEMY:
			return other.faction_state.faction == C_Faction.FactionType.PLAYER
		C_Faction.FactionType.NON_HUMAN_ENEMY:
			return other.faction_state.faction in [C_Faction.FactionType.PLAYER, C_Faction.FactionType.HUMAN_ENEMY]
		_:
			return false
