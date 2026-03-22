## C_Faction
##
## ECS component that identifies which faction an entity belongs to.
## The [method is_hostile_to] helper is used by AI targeting and combat
## systems to determine valid attack targets without requiring hard-coded
## entity type checks.
##
## Applied to: Player, Human Enemies, Non-Human Enemies.
class_name C_Faction
extends Component

## All recognised factions in the game.
enum FactionType {
	PLAYER,
	HUMAN_ENEMY,
	NON_HUMAN_ENEMY,
	NEUTRAL,
}

## This entity's faction.
@export var faction: FactionType = FactionType.NEUTRAL


## Returns true if this entity considers [param other] a valid attack target.
## Hostility rules (GDD §4.5):
## - Player is hostile to all enemy factions.
## - Human enemies are hostile to the Player only.
## - Non-human enemies are hostile to the Player and Human Enemies.
## - Neutral is never hostile.
func is_hostile_to(other: C_Faction) -> bool:
	if other == null:
		return false
	match faction:
		FactionType.PLAYER:
			return other.faction == FactionType.HUMAN_ENEMY \
				or other.faction == FactionType.NON_HUMAN_ENEMY
		FactionType.HUMAN_ENEMY:
			return other.faction == FactionType.PLAYER
		FactionType.NON_HUMAN_ENEMY:
			return other.faction == FactionType.PLAYER \
				or other.faction == FactionType.HUMAN_ENEMY
		_:
			return false
