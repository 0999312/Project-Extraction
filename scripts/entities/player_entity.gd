## PlayerEntity
##
## The Player's scene-tree body: a CharacterBody2D that handles physics
## movement, collision, and animation (GDD §6.1, Tech Stack §5.1).
##
## Gameplay state (HP, stamina, status effects, inventory, combat) lives
## in a child [BaseEntity] node called [member _ecs_entity].  This
## "Player Bridge" pattern keeps physics fast and ECS logic scalable:
##
##   Node (CharacterBody2D)  ←→  ECS Entity (BaseEntity child)
##     • move_and_slide()            • C_Health, C_Stamina
##     • animation player            • C_StatusEffects
##     • camera shake events         • C_CombatState
##     • InputBridge writes          • C_InventoryRef
##       move_input / aim_dir        • C_Position (synced from Node)
##
## Input is written by the InputBridge autoload (G.U.I.D.E → EventBus),
## not read directly from Input, keeping the simulation command-driven.
class_name PlayerEntity
extends CharacterBody2D

#region Constants

## Base movement speed in pixels per second (no modifiers applied).
const BASE_SPEED: float = 200.0
## Sprint speed in pixels per second (before encumbrance / status modifiers).
const BASE_SPRINT_SPEED: float = 320.0
## Stamina consumed per second while sprinting.
const STAMINA_SPRINT_COST_PER_SEC: float = 15.0

#endregion Constants


#region Public Variables

## Movement intent written each frame by the InputBridge.
## Should be a normalised or zero vector.
var move_input: Vector2 = Vector2.ZERO

## World-space direction the player is aiming (from centre of body).
## Written by the InputBridge from mouse / right-stick position.
var aim_direction: Vector2 = Vector2.RIGHT

## True while the sprint input is held and stamina allows it.
var is_sprinting: bool = false

#endregion Public Variables


#region Private Variables

## Child ECS entity that holds all authoritative gameplay state.
## Registered with the GECS World in [method _ready].
var _ecs_entity: BaseEntity = null

#endregion Private Variables


#region Godot Lifecycle

func _ready() -> void:
	_setup_ecs_entity()


func _physics_process(delta: float) -> void:
	_handle_sprint_stamina(delta)
	_sync_input_to_ecs()
	_apply_movement()
	_sync_position_to_ecs()

#endregion Godot Lifecycle


#region ECS Bridge Setup

## Creates and registers the child ECS entity, adding all gameplay-state
## components.  Called once from [method _ready].
func _setup_ecs_entity() -> void:
	_ecs_entity = BaseEntity.new()
	_ecs_entity.name = "PlayerECSState"
	add_child(_ecs_entity)

	# Build default component set.
	var health := C_Health.new()
	health.max_hp = 100.0
	health.current_hp = 100.0

	var stamina := C_Stamina.new()
	stamina.max_stamina = 100.0
	stamina.current_stamina = 100.0
	stamina.regen_rate = 10.0

	var vel := C_Velocity.new()
	vel.max_speed = BASE_SPEED

	var pos := C_Position.new()
	pos.world_position = global_position

	var faction := C_Faction.new()
	faction.faction = C_Faction.FactionType.PLAYER

	_ecs_entity.add_components([
		health,
		stamina,
		C_StatusEffects.new(),
		pos,
		vel,
		C_CombatState.new(),
		C_InventoryRef.new(),
		faction,
	])

	# Register with the active GECS World if one exists.
	if ECS.world:
		ECS.world.add_entity(_ecs_entity)

#endregion ECS Bridge Setup


#region Physics & Movement

## Consumes stamina while sprinting; disables sprint if exhausted.
func _handle_sprint_stamina(delta: float) -> void:
	if not is_sprinting or move_input.length_squared() < 0.01:
		return
	var stamina: C_Stamina = _ecs_entity.get_component(C_Stamina)
	if stamina and not stamina.consume(STAMINA_SPRINT_COST_PER_SEC * delta):
		is_sprinting = false


## Writes the resolved velocity into [C_Velocity] and applies it via
## [method CharacterBody2D.move_and_slide].
func _sync_input_to_ecs() -> void:
	if _ecs_entity == null:
		return
	var vel_comp: C_Velocity = _ecs_entity.get_component(C_Velocity)
	if vel_comp:
		vel_comp.velocity = move_input.normalized() * _get_current_speed()


## Reads [C_Velocity] and drives the CharacterBody2D.
func _apply_movement() -> void:
	if _ecs_entity == null:
		return
	var vel_comp: C_Velocity = _ecs_entity.get_component(C_Velocity)
	if vel_comp:
		velocity = vel_comp.velocity
	move_and_slide()


## Writes the updated Node position and aim angle back into [C_Position]
## so ECS systems always have an accurate world position.
func _sync_position_to_ecs() -> void:
	if _ecs_entity == null:
		return
	var pos_comp: C_Position = _ecs_entity.get_component(C_Position)
	if pos_comp:
		pos_comp.world_position = global_position
		pos_comp.facing_angle = aim_direction.angle()


## Returns the current movement speed after applying all modifiers.
func _get_current_speed() -> float:
	if _ecs_entity == null:
		return BASE_SPEED
	var selected_speed := BASE_SPRINT_SPEED if is_sprinting else BASE_SPEED
	var inv: C_InventoryRef = _ecs_entity.get_component(C_InventoryRef)
	var status: C_StatusEffects = _ecs_entity.get_component(C_StatusEffects)
	var mult := 1.0
	if inv:
		mult *= inv.get_speed_multiplier()
	if status:
		mult *= status.get_move_speed_multiplier()
	return selected_speed * mult

#endregion Physics & Movement


#region Public API

## Returns the child ECS entity holding gameplay state.
func get_ecs_entity() -> BaseEntity:
	return _ecs_entity


## Returns true if the player's HP > 0.
func is_alive() -> bool:
	if _ecs_entity == null:
		return false
	return _ecs_entity.is_alive()


## Convenience accessor — returns the [C_Health] component from the ECS entity.
func get_health() -> C_Health:
	if _ecs_entity == null:
		return null
	return _ecs_entity.get_component(C_Health)


## Convenience accessor — returns the [C_InventoryRef] component.
func get_inventory_ref() -> C_InventoryRef:
	if _ecs_entity == null:
		return null
	return _ecs_entity.get_component(C_InventoryRef)

#endregion Public API
