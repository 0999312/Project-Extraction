## HumanBase  (e_human_base.gd)
##
## Shared [CharacterBody2D] base class for all human-type physics bodies
## (Player and human enemy).
##
## Responsibilities:
##   1. Owns the [b]AimPivot[/b] rig — a [Node2D] child whose rotation follows
##      the aim direction each frame. The RightHand and LeftHand are children
##      of AimPivot, so both hands (and any held weapon) rotate 360° with it.
##   2. Exposes [method attach_weapon] and [method attach_left_hand_item] for
##      spawning weapons/items onto the correct mount point at runtime.
##   3. Declares the virtual [method _get_aim_direction] that subclasses must
##      override to supply the correct direction:
##        • [Player]          — towards the mouse cursor
##        • [HumanEnemyBody]  — towards the AI target / line-of-sight direction
##
## [b]Expected scene structure:[/b]
## [codeblock]
## ┌─ HumanBase (CharacterBody2D root)
## │   ├─ CollisionShape2D      ← capsule hitbox
## │   ├─ BodySprite            ← Sprite2D / AnimatedSprite2D body visual
## │   └─ AimPivot              ← Node2D; rotated each frame
## │       ├─ RightHand         ← Node2D; weapon mount (offset e.g. (16, 0))
## │       │   └─ HandSprite    ← Sprite2D hand visual
## │       └─ LeftHand          ← Node2D; off-hand mount (offset e.g. (10, -6))
## │           └─ HandSprite    ← Sprite2D hand visual
## [/codeblock]
##
## [b]GECS note:[/b] This is a scene-tree (physics) class, not an [Entity].
## Gameplay state lives in the ECS entity child added by subclasses.
class_name HumanBase
extends BiologicalBodyBase


#region Constants

## Minimum squared vector length before treating a direction as valid.
## Used to avoid normalising a near-zero vector (which produces NaN).
const AIM_EPSILON: float = 0.0001

#endregion Constants


#region Node References

## Pivot node that rotates to face the aim direction each physics frame.
## Its children (hands, held weapons) inherit the rotation for free.
@onready var _aim_pivot: Node2D = $AimPivot

## Primary-hand mount point (trigger hand / weapon hand).
## Positioned outward from the pivot origin (e.g. [code]Vector2(16, 0)[/code]).
@onready var _right_hand: Node2D = $AimPivot/RightHand

## Off-hand mount point (support / secondary item).
## Positioned slightly inward and offset from the right hand.
@onready var _left_hand: Node2D = $AimPivot/LeftHand

#endregion Node References


#region Godot Lifecycle

## Rotates the AimPivot on every physics tick.
## Subclasses should call [code]super(delta)[/code] first so the pivot is
## updated before any weapon-position-dependent logic runs.
func _physics_process(delta: float) -> void:
	_update_aim_pivot()

#endregion Godot Lifecycle


#region Aim Pivot

## Reads [method _get_aim_direction] and applies it to [member _aim_pivot].
## Called automatically each physics frame by [method _physics_process].
func _update_aim_pivot() -> void:
	if _aim_pivot == null:
		return
	var dir := _get_aim_direction()
	if dir.length_squared() > AIM_EPSILON:
		_aim_pivot.rotation = dir.angle()

#endregion Aim Pivot


#region Virtual: Aim Direction

## Returns the normalised world-space direction this entity is aiming.
##
## [b]Override in every subclass:[/b]
##   • [Player] — [code]return (get_global_mouse_position() - global_position).normalized()[/code]
##   • [HumanEnemyBody] — reads [C_AimState.aim_direction] from the ECS entity
##
## Default returns [code]Vector2.RIGHT[/code] (east / facing right).
func _get_aim_direction() -> Vector2:
	return Vector2.RIGHT

#endregion Virtual: Aim Direction


#region Hand / Weapon API

## Attaches [param weapon_node] to the right-hand (primary weapon) mount point.
## Any existing weapon children of [member _right_hand] are freed first.
##
## The weapon will automatically follow the AimPivot rotation, achieving the
## full 360° weapon-tracking behaviour required by the GDD.
func attach_weapon(weapon_node: Node2D) -> void:
	if _right_hand == null:
		push_error("HumanBase.attach_weapon: RightHand node not found.")
		return
	for child in _right_hand.get_children():
		child.queue_free()
	_right_hand.add_child(weapon_node)


## Attaches [param item_node] to the left-hand (off-hand) mount point.
## Any existing item children of [member _left_hand] are freed first.
func attach_left_hand_item(item_node: Node2D) -> void:
	if _left_hand == null:
		push_error("HumanBase.attach_left_hand_item: LeftHand node not found.")
		return
	for child in _left_hand.get_children():
		child.queue_free()
	_left_hand.add_child(item_node)


## Returns the world-space muzzle / weapon-tip position (right-hand mount).
## CombatSystem uses this as the spawn point for projectiles.
func get_muzzle_position() -> Vector2:
	if _right_hand == null:
		return global_position
	return _right_hand.global_position

#endregion Hand / Weapon API
