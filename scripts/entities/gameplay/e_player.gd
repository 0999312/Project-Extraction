## Player  (e_player.gd)
##
## The Player's scene-tree body: a [CharacterBody2D] that handles physics
## movement, collision, and animation (GDD §6.1, Tech Stack §5.1).
##
## Extends [HumanBase] to inherit the AimPivot rig (left/right hands + weapon
## 360° rotation). Overrides [method HumanBase._get_aim_direction] to use the
## current mouse cursor position as the aim point.
##
## [b]GECS Best Practice — Hybrid Node + ECS Bridge:[/b]
## Gameplay state (HP, stamina, status effects, inventory, combat) lives in a
## child [BaseEntity] node called [code]_ecs_entity[/code]. This pattern keeps
## physics fast and ECS logic scalable:
##
##   Node (CharacterBody2D)        ECS Entity (BaseEntity child)
##   ─────────────────────         ─────────────────────────────
##   move_and_slide()              C_Health, C_Stamina
##   animation player              C_StatusEffects
##   camera shake events           C_CombatState, C_InventoryRef
##   InputBridge writes            C_Position (synced from Node)
##   move_input / aim_dir          C_Velocity, C_Faction, C_AimState
##
## Input is written by the InputBridge autoload (G.U.I.D.E → EventBus),
## not read directly from [Input], keeping the simulation command-driven.
##
## [b]Component data is modified directly[/b] — no logic methods on components.
class_name Player
extends HumanBase


#region Constants

## Base walking speed in pixels per second (no modifiers applied).
const BASE_SPEED: float = 200.0
## Sprint speed in pixels per second (before encumbrance / status modifiers).
const BASE_SPRINT_SPEED: float = 320.0
## Stamina consumed per second while sprinting.
const STAMINA_SPRINT_COST_PER_SEC: float = 15.0

#endregion Constants


#region Public Variables

## Movement intent written each frame by InputBridge. Should be normalised or zero.
var move_input: Vector2 = Vector2.ZERO

## World-space aiming direction (from centre of body).
## Written by InputBridge from mouse position or right-stick input.
var aim_direction: Vector2 = Vector2.RIGHT

## [code]true[/code] while the sprint input is held and stamina allows it.
var is_sprinting: bool = false

#endregion Public Variables


#region Private Variables

## Child [BaseEntity] that holds all authoritative gameplay state components.
## Registered with the GECS World during [method _ready].
var _ecs_entity: BaseEntity = null

#endregion Private Variables


#region Godot Lifecycle

func _ready() -> void:
	_setup_ecs_entity()


## Updates the aim pivot (via [HumanBase]), handles sprint stamina, applies
## physics movement, and syncs state back to ECS.
func _physics_process(delta: float) -> void:
	super(delta)  # HumanBase: rotates _aim_pivot to face mouse cursor
	_handle_sprint_stamina(delta)
	_sync_input_to_ecs()
	_apply_movement()
	_sync_position_to_ecs()

#endregion Godot Lifecycle


#region ECS Bridge Setup

## Creates and registers the child [BaseEntity], adding all gameplay-state
## [Component]s using [code]_init()[/code] constructors (GECS Best Practice).
## Called once from [method _ready].
func _setup_ecs_entity() -> void:
	_ecs_entity = BaseEntity.new()
	_ecs_entity.name = "PlayerECSState"
	add_child(_ecs_entity)

	# Use _init() constructors for compact, readable component setup.
	var pos := C_Position.new(global_position)

	_ecs_entity.add_components([
		C_Health.new(100.0),
		C_Stamina.new(100.0, 10.0),
		C_StatusEffects.new(),
		pos,
		C_Velocity.new(BASE_SPEED),
		C_CombatState.new(),
		C_InventoryRef.new(),
		C_Faction.new(C_Faction.FactionType.PLAYER),
		C_AimState.new(),  # Written each frame in _sync_position_to_ecs()
	])

	# Register with the active GECS World if one exists.
	if ECS.world:
		ECS.world.add_entity(_ecs_entity)

#endregion ECS Bridge Setup


#region Aim Direction Override

## Returns the direction from the Player's body centre to the mouse cursor.
## This is fed into [HumanBase._update_aim_pivot] to rotate the arm/weapon rig.
##
## Falls back to [member aim_direction] if the mouse is exactly on the entity
## (avoids a zero-length normalisation).
func _get_aim_direction() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length_squared() > AIM_EPSILON:
		return to_mouse.normalized()
	# Fallback: keep last known aim direction set by InputBridge.
	return aim_direction if aim_direction != Vector2.ZERO else Vector2.RIGHT

#endregion Aim Direction Override


#region Physics & Movement

## Consumes stamina while sprinting; disables sprint when exhausted.
## Directly modifies [C_Stamina] fields — no logic methods on the component.
func _handle_sprint_stamina(delta: float) -> void:
	if not is_sprinting or move_input.length_squared() < 0.01:
		return
	var stamina: C_Stamina = _ecs_entity.get_component(C_Stamina)
	if stamina == null:
		return
	var cost := STAMINA_SPRINT_COST_PER_SEC * delta
	if stamina.current_stamina < cost:
		# Not enough stamina — cancel sprint.
		is_sprinting = false
		return
	# Direct field modification — SprintSystem would own this in full ECS.
	stamina.current_stamina = maxf(0.0, stamina.current_stamina - cost)
	if stamina.current_stamina < stamina.exhaustion_threshold:
		stamina.is_exhausted = true


## Resolves the target velocity and writes it into [C_Velocity].
func _sync_input_to_ecs() -> void:
	if _ecs_entity == null:
		return
	var vel_comp: C_Velocity = _ecs_entity.get_component(C_Velocity)
	if vel_comp:
		vel_comp.velocity = move_input.normalized() * _get_current_speed()


## Reads [C_Velocity.velocity] and drives [method CharacterBody2D.move_and_slide].
func _apply_movement() -> void:
	if _ecs_entity == null:
		return
	var vel_comp: C_Velocity = _ecs_entity.get_component(C_Velocity)
	if vel_comp:
		velocity = vel_comp.velocity
	move_and_slide()


## Writes the post-slide Node position and aim angle back into [C_Position]
## and [C_AimState] so ECS systems always read an accurate world position
## and aim direction.
func _sync_position_to_ecs() -> void:
	if _ecs_entity == null:
		return
	var pos_comp: C_Position = _ecs_entity.get_component(C_Position)
	if pos_comp:
		pos_comp.world_position = global_position
		pos_comp.facing_angle = aim_direction.angle()
	# Keep C_AimState in sync so CombatSystem and observers can read it.
	var aim_comp: C_AimState = _ecs_entity.get_component(C_AimState)
	if aim_comp:
		aim_comp.aim_direction = _get_aim_direction()


## Returns the current movement speed after applying encumbrance and status
## modifiers. Reads [Component] data fields directly — no logic methods.
func _get_current_speed() -> float:
	if _ecs_entity == null:
		return BASE_SPEED
	var selected_speed := BASE_SPRINT_SPEED if is_sprinting else BASE_SPEED
	var inv: C_InventoryRef = _ecs_entity.get_component(C_InventoryRef)
	var status: C_StatusEffects = _ecs_entity.get_component(C_StatusEffects)
	var mult := 1.0
	# Encumbrance multiplier (GDD §4.1): scales from 1.0 at 0 % to 0.5 at 100 % weight.
	if inv and inv.max_weight > 0.0:
		var enc_ratio := inv.current_weight / inv.max_weight
		mult *= clampf(1.0 - enc_ratio * 0.5, 0.3, 1.0)
	# Fracture penalty (GDD §4.1): directly read from C_StatusEffects data field.
	if status and status.fracture:
		mult *= status.fracture_move_speed_mult
	return selected_speed * mult

#endregion Physics & Movement


#region Public API

## Returns the child [BaseEntity] holding gameplay state.
func get_ecs_entity() -> BaseEntity:
	return _ecs_entity


## Returns [code]true[/code] if the player's HP > 0.
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
