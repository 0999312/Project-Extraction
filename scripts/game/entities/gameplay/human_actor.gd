class_name HumanActor
extends BiologicalActor

const AIM_EPSILON: float = 0.0001

## Base color tint for this human actor's body sprite.
## Override in subclasses or set per-instance for different colored characters.
var body_color: Color = Color.WHITE

@onready var _aim_pivot: Node2D = $AimPivot
@onready var _item_root: Node2D = $AimPivot/Item
@onready var _right_hand: Node2D = $AimPivot/Item/RightHand
@onready var _left_hand: Node2D = $AimPivot/Item/LeftHand
@onready var _item_pivot: Node2D = $AimPivot/Item/ItemPivot
@onready var _item_sprite: Sprite2D = $AimPivot/Item/ItemPivot/ItemSprite
@onready var _body_sprite: Sprite2D = $BodySprite
@onready var _right_hand_sprite: Sprite2D = $AimPivot/Item/RightHand/HandSprite
@onready var _left_hand_sprite: Sprite2D = $AimPivot/Item/LeftHand/HandSprite

func _ready() -> void:
	super._ready()
	_apply_body_color()
	_sync_current_held_item_visual()

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
	if _item_pivot == null:
		LocalizedText.error("logs.human_actor.item_pivot_missing")
		return
	_clear_children_except(_item_pivot, _item_sprite)
	if _item_sprite != null:
		_item_sprite.visible = false
	_item_pivot.add_child(weapon_node)

func attach_left_hand_item(item_node: Node2D) -> void:
	if _left_hand == null:
		LocalizedText.error("logs.human_actor.left_hand_missing")
		return
	_clear_children_except(_left_hand, _left_hand_sprite)
	_left_hand.add_child(item_node)

func get_muzzle_position() -> Vector2:
	if _right_hand == null:
		return global_position
	return _right_hand.global_position

func sync_held_item_visual(weapon_id: String, item_id: String = "") -> void:
	if _item_sprite == null:
		return
	_clear_children_except(_item_pivot, _item_sprite)
	var resolved_weapon_id := weapon_id
	var resolved_item_id := item_id
	if resolved_weapon_id.is_empty() and not resolved_item_id.is_empty():
		var weapon_def := WeaponCatalog.get_weapon_for_item(resolved_item_id)
		if weapon_def != null:
			resolved_weapon_id = weapon_def.id
	if resolved_item_id.is_empty() and not resolved_weapon_id.is_empty():
		var weapon_def := WeaponCatalog.get_weapon_definition(resolved_weapon_id)
		if weapon_def != null:
			resolved_item_id = weapon_def.item_id
	if resolved_weapon_id.is_empty() and resolved_item_id.is_empty():
		_clear_held_item_visual()
		return
	var render_config := HeldItemRenderCatalog.get_render_config_for(resolved_weapon_id, resolved_item_id)
	_apply_held_item_render_config(render_config)

func _sync_current_held_item_visual() -> void:
	if combat_state == null:
		return
	sync_held_item_visual("", combat_state.equipped_weapon_id)

func _apply_held_item_render_config(render_config: HeldItemRenderConfig) -> void:
	if _item_sprite == null:
		return
	if render_config == null:
		_clear_held_item_visual()
		return
	var texture := _load_texture(render_config.sprite_path)
	if texture == null:
		var fallback := HeldItemRenderCatalog.get_default_render_config()
		if fallback != null and fallback != render_config:
			_apply_held_item_render_config(fallback)
			return
		_clear_held_item_visual()
		return
	_item_sprite.texture = texture
	_item_sprite.position = render_config.sprite_offset
	_item_sprite.scale = render_config.sprite_scale
	_item_sprite.rotation_degrees = render_config.sprite_rotation_deg
	_item_sprite.visible = true

func _clear_held_item_visual() -> void:
	if _item_sprite == null:
		return
	_item_sprite.texture = null
	_item_sprite.position = Vector2.ZERO
	_item_sprite.scale = Vector2.ONE
	_item_sprite.rotation = 0.0
	_item_sprite.visible = false

func _clear_children_except(parent: Node, preserved_child: Node = null) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		if child == preserved_child:
			continue
		child.queue_free()

func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var res := ResourceLoader.load(path)
	return res if res is Texture2D else null
