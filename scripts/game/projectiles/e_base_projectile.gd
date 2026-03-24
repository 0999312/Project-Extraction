class_name BaseProjectile
extends Node2D

var projectile_data: C_ProjectileData = null
var owner_faction: C_Faction.FactionType = C_Faction.FactionType.NEUTRAL
var owner_actor_id: String = ""
var weapon_id: String = ""
var _sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("projectiles")
	if projectile_data == null:
		projectile_data = C_ProjectileData.new()
	_ensure_sprite()

func setup(direction: Vector2, dmg: float, pen: float, owner_id: String, wpn_id: String) -> void:
	if projectile_data == null:
		projectile_data = C_ProjectileData.new()
	var shot_dir := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.RIGHT
	if absf(projectile_data.spread_deviation_rad) > 0.000001:
		shot_dir = shot_dir.rotated(projectile_data.spread_deviation_rad)
	projectile_data.velocity = shot_dir * projectile_data.speed
	projectile_data.damage = dmg
	projectile_data.penetration = pen
	projectile_data.owner_entity_id = owner_id
	projectile_data.weapon_id = wpn_id
	owner_actor_id = owner_id
	weapon_id = wpn_id
	rotation = shot_dir.angle()
	_ensure_sprite()

func is_hostile_to(target: BiologicalBodyBase) -> bool:
	if target == null:
		return false
	var target_faction := target.get_faction_state()
	if target_faction == null:
		return false
	match owner_faction:
		C_Faction.FactionType.PLAYER:
			return target_faction.faction in [C_Faction.FactionType.HUMAN_ENEMY, C_Faction.FactionType.NON_HUMAN_ENEMY]
		C_Faction.FactionType.HUMAN_ENEMY:
			return target_faction.faction == C_Faction.FactionType.PLAYER
		C_Faction.FactionType.NON_HUMAN_ENEMY:
			return target_faction.faction in [C_Faction.FactionType.PLAYER, C_Faction.FactionType.HUMAN_ENEMY]
		_:
			return false

func on_hit(target: BiologicalBodyBase, _hit_position: Vector2) -> void:
	if target != null:
		target.apply_damage(projectile_data.damage, owner_actor_id)
	queue_free()

func on_expire() -> void:
	queue_free()

func _ensure_sprite() -> void:
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "ProjectileSprite"
		add_child(_sprite)
	if projectile_data != null and ResourceLoader.exists(projectile_data.sprite_path):
		var texture := load(projectile_data.sprite_path)
		if texture is Texture2D:
			_sprite.texture = texture
