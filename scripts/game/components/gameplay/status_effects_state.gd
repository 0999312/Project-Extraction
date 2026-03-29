class_name StatusEffectsState
extends Resource

# Generic move-speed and aim-sway modifiers applied by active Buffs at runtime.
# Bleed and fracture are no longer stored here — they are modelled as Buff instances
# managed by the BuffComponent attached to the actor.
@export var move_speed_mult: float = 1.0
@export var aim_sway_mult: float = 1.0
@export var interaction_speed_mult: float = 1.0
