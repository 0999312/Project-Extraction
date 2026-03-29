class_name BuffInstance
extends RefCounted

# Represents one active application of a BuffDefinition on an actor.

## The definition this instance is based on
var definition: BuffDefinition = null

## Remaining duration in seconds. -1.0 = permanent (no expiry).
var remaining_duration: float = -1.0

## Current stack count (only used when definition.stackable is true)
var stack_count: int = 1

func _init(def: BuffDefinition) -> void:
	definition = def
	if def != null and def.base_duration > 0.0:
		remaining_duration = def.base_duration

## Returns true once the duration has expired (permanent buffs never expire).
func is_expired() -> bool:
	return remaining_duration >= 0.0 and remaining_duration <= 0.001

## Advances the timer by delta seconds and returns remaining damage to apply.
func tick(delta: float) -> float:
	if definition == null:
		return 0.0
	var dmg := definition.damage_per_second * delta * float(stack_count)
	if remaining_duration >= 0.0:
		remaining_duration = maxf(0.0, remaining_duration - delta)
	return dmg
