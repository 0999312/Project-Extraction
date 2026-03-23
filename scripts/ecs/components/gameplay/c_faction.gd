## C_Faction
##
## [b]Pure-data[/b] ECS component identifying which faction an entity belongs to.
##
## [b]GECS Best Practice:[/b] Components hold only data — no logic or behaviour.
## Hostility checks belong in Systems (AITargetingSystem, CombatSystem):
## [codeblock]
## # In a System:
## var my_fac  = attacker.get_component(C_Faction)
## var tgt_fac = target.get_component(C_Faction)
## var hostile = _are_hostile(my_fac.faction, tgt_fac.faction)
## [/codeblock]
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


## Convenience constructor.
## Usage: [code]C_Faction.new(C_Faction.FactionType.HUMAN_ENEMY)[/code]
func _init(fac: FactionType = FactionType.NEUTRAL) -> void:
	faction = fac
