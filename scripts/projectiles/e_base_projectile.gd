## BaseProjectile  (e_base_projectile.gd)
##
## Base class for all projectile ECS entities in Project Extraction
## (GDD §6.3, Tech Stack §5.3).
##
## [b]GECS Best Practice — ECS-only with pooling:[/b]
## Projectiles are pure [Entity] nodes — no per-bullet scene node is created.
## Visuals (tracers, impact sparks) are driven by pooled VFX, triggered via
## AudioBridge / UIBridge events.
##
## The [code]ProjectileSystem[/code] is responsible for:
##   - Advancing [C_ProjectileData.age] by delta each frame.
##   - Moving the projectile using [C_ProjectileData.velocity].
##   - Performing hit detection (raycasts or grid queries).
##   - Calling [method on_hit] on a valid collision.
##   - Calling [method on_expire] when [C_ProjectileData.lifetime] is exceeded.
##   - Queuing entity removal via [code]cmd.remove_entity(entity)[/code]
##     (safe deferred removal — GECS Best Practice).
##
## Subclasses can override [method on_hit] and [method on_expire] to fire
## additional ECS events (e.g. explosion radius damage, ricochet logic).
class_name BaseProjectile
extends Entity


#region Lifecycle

## Initialise this projectile after spawning.
## Writes into [C_ProjectileData] — reads component data fields directly,
## consistent with the GECS pure-data component principle.
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
	# Direct field writes — no logic methods on the component.
	proj.velocity = direction.normalized() * proj.speed
	proj.damage = dmg
	proj.penetration = pen
	proj.owner_entity_id = owner_id
	proj.weapon_id = wpn_id


## Returns the default [Component] set for every projectile.
## Use [code]C_ProjectileData.new(speed, damage, pen, lifetime)[/code]
## for variant-specific stats in subclasses.
func define_components() -> Array:
	return [
		C_ProjectileData.new(),
		C_Position.new(),
	]

#endregion Lifecycle


#region Hit & Expiry Callbacks

## Called by ProjectileSystem when this projectile hits a valid target.
##
## [param target] The entity that was struck (may be null for environment hits).
## [param hit_position] World-space position of the impact point.
##
## Override to emit ECS events (e.g. spawn impact VFX event, apply damage
## via EventBus) without accessing scene-tree Nodes directly.
func on_hit(target: Entity, hit_position: Vector2) -> void:
	pass


## Called by ProjectileSystem when [C_ProjectileData.age] exceeds
## [C_ProjectileData.lifetime] without hitting anything.
##
## Override to emit a "missed shot" VFX event if desired.
func on_expire() -> void:
	pass

#endregion Hit & Expiry Callbacks
