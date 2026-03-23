## C_Stamina
##
## [b]Pure-data[/b] ECS component for an entity's stamina pool (GDD §4.1).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Stamina consumption and regeneration belong in dedicated Systems:
##   • SprintSystem / MeleeSystem  — decrease [member current_stamina]
##   • StaminaRegenSystem          — increase [member current_stamina] each delta,
##                                   update [member is_exhausted] flag
##
## Applied to: Player, Human Enemies (optional for AI).
class_name C_Stamina
extends Component

## Maximum stamina points.
@export var max_stamina: float = 100.0
## Current stamina points. Modified directly by Systems.
@export var current_stamina: float = 100.0
## Stamina recovered per second while idle or walking.
@export var regen_rate: float = 10.0
## StaminaRegenSystem sets [member is_exhausted] when current falls below this value.
@export var exhaustion_threshold: float = 10.0
## [code]true[/code] while [member current_stamina] is below [member exhaustion_threshold].
## Read by movement/attack systems to gate sprinting and melee.
@export var is_exhausted: bool = false


## Convenience constructor.
## [param max_stam] Maximum (and starting) stamina.
## [param regen] Per-second regeneration rate.
## Usage: [code]C_Stamina.new(80.0, 5.0)[/code]
func _init(max_stam: float = 100.0, regen: float = 10.0) -> void:
	max_stamina = max_stam
	current_stamina = max_stam
	regen_rate = regen
