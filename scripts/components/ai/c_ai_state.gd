## C_AIState
##
## [b]Pure-data[/b] ECS component holding the AI state machine data for enemy
## entities (GDD §4.5, Tech Stack §5.2).
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## The AISystem reads and writes these fields each frame to drive enemy
## behaviour. Path points are provided by a navigation service so that
## individual enemies do not each need a NavigationAgent2D node.
##
## Applied to: Human Enemies, Non-Human Enemies.
class_name C_AIState
extends Component

## All states an AI-controlled enemy can occupy.
enum AIBehavior {
	IDLE,    ## Standing still; no threat detected.
	PATROL,  ## Moving between patrol waypoints.
	ALERT,   ## Suspicious; searching for noise/sighting source.
	CHASE,   ## Actively pursuing a confirmed target.
	ATTACK,  ## Within attack range; executing attack pattern.
	FLEE,    ## Retreating (e.g. below a low-HP threshold).
	DEAD,    ## Entity has died; AISystem skips this entity.
}

## Current behaviour state. Written by AISystem on every transition.
@export var behavior: AIBehavior = AIBehavior.IDLE

## Last known world position of the primary target (used in CHASE / ALERT states).
@export var last_known_target_position: Vector2 = Vector2.ZERO

## Detection radius in pixels. AISystem triggers ALERT when the player enters
## this range (line-of-sight check is a separate system concern).
@export var detection_radius: float = 300.0

## Attack-switch radius in pixels. AISystem transitions to ATTACK when the
## target is within this range.
@export var attack_radius: float = 150.0

## Index into the assigned patrol route (PATROL state).
@export var patrol_point_index: int = 0

## Seconds spent in the current [member behavior] state.
@export var state_timer: float = 0.0

## Alert accumulator (0–1). Increases when the player is partially visible or
## a noise event arrives. AISystem transitions to CHASE when this reaches 1.0.
@export var alert_level: float = 0.0

## Current navigation path provided by the navigation service.
## Each element is a world-space waypoint (Vector2).
@export var path_points: Array[Vector2] = []

## Index of the next waypoint in [member path_points] to move towards.
@export var path_index: int = 0


## Convenience constructor.
## Usage: [code]C_AIState.new(280.0, 200.0)[/code]
func _init(detect_radius: float = 300.0, atk_radius: float = 150.0) -> void:
	detection_radius = detect_radius
	attack_radius = atk_radius
