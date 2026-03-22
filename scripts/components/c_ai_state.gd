## C_AIState
##
## ECS component holding the AI state machine data for enemy entities
## (GDD §4.5, Tech Stack §5.2).
##
## The AISystem reads and writes this component each frame to drive
## enemy behaviour.  Path points are provided by a navigation service
## so that individual enemies do not each need a NavigationAgent2D node.
##
## Applied to: Human Enemies, Non-Human Enemies.
class_name C_AIState
extends Component

## All states an AI-controlled enemy can occupy.
enum AIBehavior {
	IDLE,    ## Standing still; no threat detected.
	PATROL,  ## Moving between patrol points.
	ALERT,   ## Suspicious; searching for the source of a sound or sighting.
	CHASE,   ## Actively pursuing a confirmed target.
	ATTACK,  ## Within attack range; executing attack pattern.
	FLEE,    ## Retreating (e.g. low health threshold reached).
	DEAD,    ## Entity has died; AI processing skipped.
}

## Current behaviour state.
@export var behavior: AIBehavior = AIBehavior.IDLE

## Last known world position of the primary target (used during CHASE/ALERT).
@export var last_known_target_position: Vector2 = Vector2.ZERO

## Radius within which this enemy can detect the player (line-of-sight check
## is a separate system concern).
@export var detection_radius: float = 300.0

## Radius within which this enemy will switch to ATTACK state.
@export var attack_radius: float = 150.0

## Index into the assigned patrol route (used during PATROL state).
@export var patrol_point_index: int = 0

## Time (seconds) spent in the current behavior state.
@export var state_timer: float = 0.0

## Alert level (0–1).  Accumulates when the player is partially visible or
## a noise event is received.  Reaching 1.0 triggers transition to CHASE.
@export var alert_level: float = 0.0

## Current navigation path provided by the navigation service.
## Each element is a world-space waypoint Vector2.
@export var path_points: Array[Vector2] = []

## Index of the next waypoint in [member path_points] to move towards.
@export var path_index: int = 0
