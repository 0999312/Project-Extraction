class_name FactionState
extends Resource

enum FactionType {
	PLAYER,
	HUMAN_ENEMY,
	NON_HUMAN_ENEMY,
	NEUTRAL,
}

@export var faction: FactionType = FactionType.NEUTRAL

func _init(fac: FactionType = FactionType.NEUTRAL) -> void:
	faction = fac
