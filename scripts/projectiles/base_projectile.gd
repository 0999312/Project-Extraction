## BaseProjectile
##
## Base class for all projectile ECS entities in Project Extraction
## (GDD §6.3, Tech Stack §5.3).
##
## Projectiles are ECS-only: no per-bullet Node is created.  Visuals
## (tracers, impact sparks) are handled by pooled VFX driven by events
## on the AudioBridge / UIBridge.
##
## The [code]ProjectileSystem[/code] is responsible for:
##   - Advancing [C_ProjectileData.age] each frame.
##   - Moving the projectile by [C_ProjectileData.velocity] × delta.
##   - Performing lightweight hit detection (raycast or grid check).
##   - Calling [method on_hit] on a valid collision.
##   - Calling [method on_expire] when [C_ProjectileData.lifetime] is exceeded.
##
## Subclasses can override [method on_hit] and [method on_expire] to fire
## additional ECS events (e.g. explosion damage, ricochet).
class_name BaseProjectile
extends Entity


#region Lifecycle

## Initialise the projectile's [C_ProjectileData] after spawning.
##
## [param direction] Unit vector pointing in the travel direction.
## [param dmg] Flat damage value on hit.
## [param pen] Armor penetration value.
## [param owner_id] Entity ID string of the shooter (prevents self-hit).
## [param wpn_id] ResourceLocation string of the source weapon.
func setup(
	direction: Vector2,
	dmg: float,
	pen: float,
	owner_id: String,
	wpn_id: String
) -> void:
	var proj: C_ProjectileData = get_component(C_ProjectileData)
	if proj == null:
		push_error("BaseProjectile.setup: C_ProjectileData component is missing.")
		return
	proj.velocity = direction.normalized() * proj.speed
	proj.damage = dmg
	proj.penetration = pen
	proj.owner_entity_id = owner_id
	proj.weapon_id = wpn_id


## Override [method Entity.define_components] to provide the default
## components every projectile needs.
func define_components() -> Array:
	return [
		C_ProjectileData.new(),
		C_Position.new(),
	]

#endregion Lifecycle


#region Hit & Expiry Callbacks

## Called by the ProjectileSystem when this projectile hits a valid target.
##
## [param target] The entity that was struck (may be null for environment hits).
## [param hit_position] World-space position of the impact point.
##
## Override to emit ECS events (e.g. spawn impact VFX event, apply damage
## relationship) without touching Nodes directly.
func on_hit(target: Entity, hit_position: Vector2) -> void:
	pass


## Called by the ProjectileSystem when [C_ProjectileData.age] exceeds
## [C_ProjectileData.lifetime] without hitting anything.
##
## Override to emit a "missed shot" VFX event if desired.
func on_expire() -> void:
	pass

#endregion Hit & Expiry Callbacks
