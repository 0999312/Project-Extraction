## C_Stamina
##
## ECS component that tracks an entity's stamina pool.
## Stamina gates sprinting and melee attacks (GDD §4.1).
## Applied to: Player, Human Enemies (optional for AI).
class_name C_Stamina
extends Component

## Maximum stamina points.
@export var max_stamina: float = 100.0
## Current stamina points.
@export var current_stamina: float = 100.0
## Stamina recovered per second while not consuming.
@export var regen_rate: float = 10.0
## Falling below this value marks the entity as exhausted.
@export var exhaustion_threshold: float = 10.0
## True while current_stamina < exhaustion_threshold.
@export var is_exhausted: bool = false


## Attempt to spend [param amount] stamina. Returns false if insufficient.
func consume(amount: float) -> bool:
	if current_stamina < amount:
		return false
	current_stamina = maxf(0.0, current_stamina - amount)
	if current_stamina < exhaustion_threshold:
		is_exhausted = true
	return true


## Regenerate stamina each frame. Call from a system passing [param delta].
func regen(delta: float) -> void:
	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)
	if current_stamina >= exhaustion_threshold:
		is_exhausted = false


## Returns current stamina as a 0–1 ratio.
func get_stamina_ratio() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return current_stamina / max_stamina
