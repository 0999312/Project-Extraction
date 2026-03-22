## C_Health
##
## ECS component that stores an entity's hit point pool.
## Applied to: Player, Human Enemies, Non-Human Enemies.
## Systems read this component to determine whether an entity is alive
## and to apply damage or healing.
class_name C_Health
extends Component

## Maximum hit points.
@export var max_hp: float = 100.0
## Current hit points. Clamped to [0, max_hp] by helper methods.
@export var current_hp: float = 100.0
## Set to true when current_hp reaches 0. Systems check this flag to trigger death.
@export var is_dead: bool = false


## Reduce current_hp by [param amount]. Clamps to 0 and sets [member is_dead].
func take_damage(amount: float) -> void:
	current_hp = maxf(0.0, current_hp - amount)
	if current_hp <= 0.0:
		is_dead = true


## Restore current_hp by [param amount]. Clamps to [member max_hp].
func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = minf(max_hp, current_hp + amount)


## Returns current HP as a 0–1 ratio for UI bars and LOD decisions.
func get_hp_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
