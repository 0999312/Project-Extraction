class_name BuffComponent
extends Node

# Manages active BuffInstances on a BiologicalActor.
# Attach as a child node to any actor that needs buff support.
# Call tick(delta) from the actor's _physics_process.

signal buff_applied(buff_id: String)
signal buff_removed(buff_id: String)

## Reference to the owning actor (set automatically in _ready if parent is BiologicalActor)
var actor: BiologicalActor = null

## Active buffs keyed by definition ID.
## Non-stackable: single BuffInstance per ID.
## Stackable: single BuffInstance with stack_count > 1.
var _active: Dictionary = {}

func _ready() -> void:
	if get_parent() is BiologicalActor:
		actor = get_parent() as BiologicalActor

## Apply a buff by definition ID, looked up from BuffCatalog.
func apply_buff(buff_id: String) -> void:
	var def: BuffDefinition = BuffCatalog.get_definition(buff_id)
	if def == null:
		push_error("[BuffComponent] Unknown buff id: %s" % buff_id)
		return
	if _active.has(buff_id):
		var inst: BuffInstance = _active[buff_id]
		if def.stackable and (def.max_stacks == 0 or inst.stack_count < def.max_stacks):
			inst.stack_count += 1
		# Refresh duration on re-application
		if def.base_duration > 0.0:
			inst.remaining_duration = def.base_duration
	else:
		var inst := BuffInstance.new(def)
		_active[buff_id] = inst
		buff_applied.emit(buff_id)
	_rebuild_status_effects()

## Remove a buff by definition ID.
func remove_buff(buff_id: String) -> void:
	if not _active.has(buff_id):
		return
	_active.erase(buff_id)
	buff_removed.emit(buff_id)
	_rebuild_status_effects()

## Returns true if the buff is currently active.
func has_buff(buff_id: String) -> bool:
	return _active.has(buff_id)

## Call from the actor's _physics_process to advance timers and apply periodic damage.
func tick(delta: float) -> void:
	if actor == null:
		return
	var expired: Array[String] = []
	for buff_id in _active.keys():
		var inst: BuffInstance = _active[buff_id]
		var dmg := inst.tick(delta)
		if dmg > 0.0:
			actor.apply_damage(dmg)
		if inst.is_expired():
			expired.append(buff_id)
	for buff_id in expired:
		remove_buff(buff_id)

## Recompute the aggregate multipliers on the actor's StatusEffectsState.
func _rebuild_status_effects() -> void:
	if actor == null or actor.status_effects == null:
		return
	var move_mult := 1.0
	var aim_mult := 1.0
	var interact_mult := 1.0
	for inst: BuffInstance in _active.values():
		if inst.definition == null:
			continue
		move_mult *= inst.definition.move_speed_mult
		aim_mult *= inst.definition.aim_sway_mult
		interact_mult *= inst.definition.interaction_speed_mult
	actor.status_effects.move_speed_mult = move_mult
	actor.status_effects.aim_sway_mult = aim_mult
	actor.status_effects.interaction_speed_mult = interact_mult
