## C_StatusEffects
##
## [b]Pure-data[/b] ECS component tracking lightweight injury states (GDD §4.1).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## The state flags here are read and written by dedicated Systems:
##   • BleedSystem      — applies [member bleed_light_dps] / [member bleed_heavy_dps]
##                        damage each frame when the respective bleed flag is set
##   • MovementSystem   — reads [member fracture] and [member fracture_move_speed_mult]
##                        to scale movement speed
##   • CombatSystem     — reads [member pain] and [member pain_aim_sway_mult]
##                        to scale aim spread
##   • InteractSystem   — reads [member pain] and [member pain_interaction_speed_mult]
##                        to scale looting / healing speed
##
## Applied to: Player, Human Enemies, Non-Human Enemies.
class_name C_StatusEffects
extends Component

## Light bleeding: low damage per second; cleared by a bandage item.
@export var bleed_light: bool = false
## Heavy bleeding: high damage per second; requires a hemostat or tourniquet.
@export var bleed_heavy: bool = false
## Pain state: increases aim sway and slows interactions.
@export var pain: bool = false
## Fracture (post-Milestone-1 feature): reduces movement speed.
@export var fracture: bool = false

## Damage per second applied by BleedSystem when [member bleed_light] is true.
@export var bleed_light_dps: float = 1.0
## Damage per second applied by BleedSystem when [member bleed_heavy] is true.
@export var bleed_heavy_dps: float = 5.0

## Aim-sway multiplier used by CombatSystem when [member pain] is true.
## Values > 1 increase bullet spread and inaccuracy.
@export var pain_aim_sway_mult: float = 1.5
## Interaction-speed multiplier used by InteractSystem when [member pain] is true.
## Values < 1 slow looting and healing actions.
@export var pain_interaction_speed_mult: float = 0.75
## Move-speed multiplier used by MovementSystem when [member fracture] is true.
## Values < 1 reduce walking speed.
@export var fracture_move_speed_mult: float = 0.6
