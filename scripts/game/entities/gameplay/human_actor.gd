class_name HumanActor
extends BiologicalActor

const AIM_EPSILON: float = 0.0001

## Base color tint for this human actor's body sprite.
## Override in subclasses or set per-instance for different colored characters.
var body_color: Color = Color.WHITE

@onready var _aim_pivot: Node2D = $AimPivot
@onready var _right_hand: Node2D = $AimPivot/RightHand
@onready var _left_hand: Node2D = $AimPivot/LeftHand
@onready var _body_sprite: Sprite2D = $BodySprite
@onready var _right_hand_sprite: Sprite2D = $AimPivot/RightHand/HandSprite
@onready var _left_hand_sprite: Sprite2D = $AimPivot/LeftHand/HandSprite

func _ready() -> void:
	super._ready()
	_apply_body_color()

func _physics_process(_delta: float) -> void:
	_update_aim_pivot()
	_update_sprite_flip()

func _apply_body_color() -> void:
	if _body_sprite != null:
		_body_sprite.modulate = body_color
	if _right_hand_sprite != null:
		_right_hand_sprite.modulate = body_color
	if _left_hand_sprite != null:
		_left_hand_sprite.modulate = body_color

func _update_aim_pivot() -> void:
	if _aim_pivot == null:
		return
	var dir := _get_aim_direction()
	if dir.length_squared() > AIM_EPSILON:
		_aim_pivot.rotation = dir.angle()

func _update_sprite_flip() -> void:
	var dir := _get_aim_direction()
	var facing_left := dir.x < 0.0
	if _body_sprite != null:
		_body_sprite.flip_h = facing_left
	if _aim_pivot != null:
		_aim_pivot.scale.y = -1.0 if facing_left else 1.0

func _get_aim_direction() -> Vector2:
	if aim_state != null and aim_state.aim_direction.length_squared() > AIM_EPSILON:
		return aim_state.aim_direction
	return Vector2.RIGHT

func attach_weapon(weapon_node: Node2D) -> void:
	if _right_hand == null:
		push_error("HumanActor.attach_weapon: RightHand node not found.")
		return
	for child in _right_hand.get_children():
		child.queue_free()
	_right_hand.add_child(weapon_node)

func attach_left_hand_item(item_node: Node2D) -> void:
	if _left_hand == null:
		push_error("HumanActor.attach_left_hand_item: LeftHand node not found.")
		return
	for child in _left_hand.get_children():
		child.queue_free()
	_left_hand.add_child(item_node)

func get_muzzle_position() -> Vector2:
	if _right_hand == null:
		return global_position
	return _right_hand.global_position
