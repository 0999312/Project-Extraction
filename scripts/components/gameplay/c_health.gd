## C_Health
##
## [b]Pure-data[/b] ECS component for an entity's hit point pool (GDD §4.1).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Damage, healing and death decisions belong in dedicated Systems:
##   • DamageSystem   — subtracts from [member current_hp], sets [member is_dead]
##   • HealSystem     — adds to [member current_hp], enforces [member max_hp] cap
##   • RegenSystem    — applies [member regen_rate] per second when > 0
##
## Applied to: Player, Human Enemies, Non-Human Enemies.
class_name C_Health
extends Component

## Current hit points. Modified directly by Systems; never goes below 0.
@export var current_hp: float = 100.0
## Maximum hit points.
@export var max_hp: float = 100.0
## Passive HP regeneration per second (0 = no regeneration).
@export var regen_rate: float = 0.0
## Set to [code]true[/code] by DamageSystem when [member current_hp] reaches 0.
## Systems that skip dead entities query: [code]q.with_all([C_Health]).with_none([C_Dead])[/code]
## or check this flag directly.
@export var is_dead: bool = false


## Convenience constructor — sets both [member current_hp] and [member max_hp]
## to [param max_health] so the entity starts at full health.
## Usage: [code]C_Health.new(80.0)[/code]
func _init(max_health: float = 100.0) -> void:
	max_hp = max_health
	current_hp = max_health
